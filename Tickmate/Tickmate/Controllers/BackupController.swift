//
//  BackupController.swift
//  Tickmate
//
//  Created by Elaine Lyons on 5/12/26.
//

import CoreData
import Foundation

enum ImportMode {
    case replace
    case merge
}

enum BackupError: LocalizedError {
    case newerVersion(Int)
    case invalidFormat
    case readFailed
    case androidImportFailed(String)

    var errorDescription: String? {
        switch self {
        case .newerVersion(let version):
            return "This backup was made with a newer version of Tickmate (format version \(version)). Please update the app before importing."
        case .invalidFormat:
            return "The file is not a valid Tickmate backup."
        case .readFailed:
            return "Could not read the backup file."
        case .androidImportFailed(let message):
            return message
        }
    }
}

struct BackupController {

    // MARK: - Encoder / Decoder

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Export

    static func export(
        tracks: [Track],
        includeSettings: Bool
    ) throws -> URL {
        var archive = BackupArchive()
        archive.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        archive.appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        archive.exportDate = Date()

        // Build group map: CoreData object -> synthetic UUID
        var groupIDMap: [NSManagedObjectID: String] = [:]
        var referencedGroups = Set<NSManagedObjectID>()

        // Determine which groups are referenced by the selected tracks
        for track in tracks {
            if let groups = track.groups as? Set<TrackGroup> {
                for group in groups {
                    referencedGroups.insert(group.objectID)
                    if groupIDMap[group.objectID] == nil {
                        groupIDMap[group.objectID] = UUID().uuidString
                    }
                }
            }
        }

        // Export referenced groups, sorted by index for stable output
        var backupGroups: [BackupGroup] = []
        let referencedGroupObjects = tracks
            .compactMap { $0.groups as? Set<TrackGroup> }
            .flatMap { $0 }
            .filter { referencedGroups.contains($0.objectID) }
        let seen = NSMutableSet()
        for group in referencedGroupObjects.sorted(by: { $0.index < $1.index }) {
            guard !seen.contains(group.objectID) else { continue }
            seen.add(group.objectID)
            let uuid = groupIDMap[group.objectID]!
            backupGroups.append(BackupGroup(
                id: uuid,
                index: group.index,
                name: group.name
            ))
        }
        archive.groups = backupGroups

        // Export selected tracks
        var backupTracks: [BackupTrack] = []
        for track in tracks {
            let trackGroupIDs: [String] = (track.groups as? Set<TrackGroup>)?.compactMap { groupIDMap[$0.objectID] } ?? []

            var backupTicks: [BackupTick] = []
            if let ticks = track.ticks as? Set<Tick> {
                for tick in ticks.sorted(by: { $0.dayOffset < $1.dayOffset }) {
                    backupTicks.append(BackupTick(
                        dayOffset: tick.dayOffset,
                        count: tick.count,
                        duplicate: tick.duplicate,
                        modified: tick.modified
                    ))
                }
            }

            backupTracks.append(BackupTrack(
                id: UUID().uuidString,
                name: track.name,
                color: track.color,
                enabled: track.enabled,
                index: track.index,
                isArchived: track.isArchived,
                multiple: track.multiple,
                reversed: track.reversed,
                startDate: track.startDate,
                systemImage: track.systemImage,
                groupIDs: trackGroupIDs,
                ticks: backupTicks
            ))
        }
        archive.tracks = backupTracks

        // Settings
        if includeSettings {
            archive.settings = readSettings()
        }

        let data = try encoder.encode(archive)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        let filename = "Tickmate Backup \(dateString).tickmatebackup"

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url)
        return url
    }

    // MARK: - Import

    static func importBackup(
        from url: URL,
        mode: ImportMode,
        restoreSettings: Bool
    ) throws {
        let context = PersistenceController.shared.container.viewContext
        guard url.startAccessingSecurityScopedResource() || true else {
            throw BackupError.readFailed
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw BackupError.readFailed
        }

        let archive: BackupArchive
        do {
            archive = try decoder.decode(BackupArchive.self, from: data)
        } catch {
            do {
                archive = try AndroidDatabaseImporter.backupArchive(from: url)
            } catch AndroidDatabaseImportError.invalidFormat {
                throw BackupError.invalidFormat
            } catch {
                throw BackupError.androidImportFailed(error.localizedDescription)
            }
        }

        try importArchive(
            archive,
            mode: mode,
            restoreSettings: restoreSettings,
            context: context
        )
    }

    private static func importArchive(
        _ archive: BackupArchive,
        mode: ImportMode,
        restoreSettings: Bool,
        context: NSManagedObjectContext
    ) throws {
        guard archive.format == "tickmate-backup" else {
            throw BackupError.invalidFormat
        }

        if archive.formatVersion > BackupArchive.currentFormatVersion {
            throw BackupError.newerVersion(archive.formatVersion)
        }

        // Replace mode: delete all existing data
        if mode == .replace {
            try batchDelete(entity: "Tick", context: context)
            try batchDelete(entity: "Track", context: context)
            try batchDelete(entity: "TrackGroup", context: context)
        }

        // Import groups, mapping backup UUIDs to new Core Data objects
        var groupMap: [String: TrackGroup] = [:]
        if let groups = archive.groups {
            for backupGroup in groups {
                let group = TrackGroup(
                    name: backupGroup.name,
                    index: backupGroup.index ?? 0,
                    context: context
                )
                if let id = backupGroup.id {
                    groupMap[id] = group
                }
            }
        }

        // Import tracks with their ticks
        if let tracks = archive.tracks {
            for backupTrack in tracks {
                let track = Track(
                    name: backupTrack.name ?? "",
                    color: backupTrack.color,
                    multiple: backupTrack.multiple ?? false,
                    reversed: backupTrack.reversed ?? false,
                    startDate: backupTrack.startDate ?? TrackController.iso8601.string(from: Date()),
                    systemImage: backupTrack.systemImage,
                    index: backupTrack.index ?? 0,
                    isArchived: backupTrack.isArchived ?? false,
                    context: context
                )
                track.enabled = backupTrack.enabled ?? true

                // Wire up group relationships
                if let groupIDs = backupTrack.groupIDs {
                    let groups = groupIDs.compactMap { groupMap[$0] }
                    track.groups = NSSet(array: groups)
                }

                // Import ticks
                if let ticks = backupTrack.ticks {
                    for backupTick in ticks {
                        let tick = Tick(
                            track: track,
                            dayOffset: backupTick.dayOffset ?? 0,
                            context: context
                        )
                        tick.count = backupTick.count ?? 1
                        tick.duplicate = backupTick.duplicate ?? false
                        if let modified = backupTick.modified {
                            tick.modified = modified
                        }
                    }
                }
            }
        }

        // Settings
        if restoreSettings, let settings = archive.settings {
            writeSettings(settings)
        }

        // Unlock groups if the backup contains any
        if !groupMap.isEmpty {
            UserDefaults.standard.set(true, forKey: StoreController.Products.groups.rawValue)
        }

        try context.save()
    }

    // MARK: - Settings helpers

    private static func readSettings() -> BackupSettings {
        let standard = UserDefaults.standard
        let appGroup = UserDefaults(suiteName: groupID)

        return BackupSettings(
            customDayStart: appGroup?.bool(forKey: Defaults.customDayStart.rawValue),
            customDayStartMinutes: appGroup?.integer(forKey: Defaults.customDayStartMinutes.rawValue),
            weekStartDay: appGroup?.integer(forKey: Defaults.weekStartDay.rawValue),
            weekSeparatorSpaces: standard.bool(forKey: Defaults.weekSeparatorSpaces.rawValue),
            weekSeparatorLines: standard.bool(forKey: Defaults.weekSeparatorLines.rawValue),
            relativeDates: standard.bool(forKey: Defaults.relativeDates.rawValue),
            showAllTracks: standard.bool(forKey: Defaults.showAllTracks.rawValue),
            showUngroupedTracks: standard.bool(forKey: Defaults.showUngroupedTracks.rawValue),
            todayAtTop: appGroup?.bool(forKey: Defaults.todayAtTop.rawValue),
            todayLock: appGroup?.bool(forKey: Defaults.todayLock.rawValue)
        )
    }

    static func writeSettings(_ settings: BackupSettings) {
        let standard = UserDefaults.standard
        let appGroup = UserDefaults(suiteName: groupID)

        if let v = settings.customDayStart { appGroup?.set(v, forKey: Defaults.customDayStart.rawValue) }
        if let v = settings.customDayStartMinutes { appGroup?.set(v, forKey: Defaults.customDayStartMinutes.rawValue) }
        if let v = settings.weekStartDay { appGroup?.set(v, forKey: Defaults.weekStartDay.rawValue) }
        if let v = settings.weekSeparatorSpaces { standard.set(v, forKey: Defaults.weekSeparatorSpaces.rawValue) }
        if let v = settings.weekSeparatorLines { standard.set(v, forKey: Defaults.weekSeparatorLines.rawValue) }
        if let v = settings.relativeDates { standard.set(v, forKey: Defaults.relativeDates.rawValue) }
        if let v = settings.showAllTracks { standard.set(v, forKey: Defaults.showAllTracks.rawValue) }
        if let v = settings.showUngroupedTracks { standard.set(v, forKey: Defaults.showUngroupedTracks.rawValue) }
        if let v = settings.todayAtTop { appGroup?.set(v, forKey: Defaults.todayAtTop.rawValue) }
        if let v = settings.todayLock { appGroup?.set(v, forKey: Defaults.todayLock.rawValue) }
    }

    // MARK: - Helpers

    private static func batchDelete(entity: String, context: NSManagedObjectContext) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs

        let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
        if let objectIDs = result?.result as? [NSManagedObjectID] {
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                into: [context]
            )
        }
    }
}
