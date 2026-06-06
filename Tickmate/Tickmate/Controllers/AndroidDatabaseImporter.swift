//
//  AndroidDatabaseImporter.swift
//  Tickmate
//
//  Converts the Android Tickmate SQLite database export into Tickmate's
//  platform-neutral BackupArchive format.
//

import Foundation
import SQLite3

enum AndroidDatabaseImportError: LocalizedError {
    case invalidFormat
    case sqliteError(String)

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "The file is not a valid Android Tickmate database export."
        case .sqliteError(let message):
            return message
        }
    }
}

struct AndroidDatabaseImporter {
    private struct AndroidTrack {
        let id: Int
        let name: String
        let icon: String?
        let enabled: Bool
        let multiple: Bool
        let color: Int32
        let index: Int16
    }

    private struct AndroidGroup {
        let id: Int
        let name: String
        let index: Int16
    }

    private struct AndroidTick {
        let trackID: Int
        let date: Date
    }

    static func backupArchive(from url: URL) throws -> BackupArchive {
        let database = try Database(url: url)
        defer { database.close() }

        guard try database.containsTable("tracks"),
              try database.containsTable("ticks") else {
            throw AndroidDatabaseImportError.invalidFormat
        }

        let tracks = try readTracks(from: database)
        let groups = try readGroups(from: database)
        let groupIDsByTrackID = try readTrackGroupRelationships(from: database)
        let ticksByTrackID = Dictionary(grouping: try readTicks(from: database), by: \.trackID)

        var archive = BackupArchive()
        archive.exportDate = Date()

        archive.groups = groups.map { group in
            BackupGroup(id: String(group.id), index: group.index, name: group.name)
        }

        archive.tracks = tracks.map { track in
            let tickDates = ticksByTrackID[track.id]?.map(\.date) ?? []
            let startDate = tickDates.min() ?? Date()
            let startDateString = isoDateString(from: startDate)
            let groupedTicks = Dictionary(grouping: tickDates) { isoDateString(from: $0) }
            let backupTicks = groupedTicks.map { _, dates in
                BackupTick(
                    dayOffset: Int16(clamping: days(from: startDate, to: dates[0])),
                    count: Int16(clamping: dates.count),
                    duplicate: false,
                    modified: dates.max()
                )
            }
            .sorted { ($0.dayOffset ?? 0) < ($1.dayOffset ?? 0) }

            return BackupTrack(
                id: String(track.id),
                name: track.name,
                color: track.color,
                enabled: track.enabled,
                index: track.index,
                isArchived: !track.enabled,
                multiple: track.multiple,
                reversed: false,
                startDate: startDateString,
                systemImage: systemImage(forAndroidIcon: track.icon, trackName: track.name),
                groupIDs: (groupIDsByTrackID[track.id] ?? []).map(String.init),
                ticks: backupTicks
            )
        }

        return archive
    }

    private static func readTracks(from database: Database) throws -> [AndroidTrack] {
        let colorColumn = try database.containsColumn("color", in: "tracks") ? "color" : "0 AS color"
        let multipleColumn = try database.containsColumn("multiple_entries_per_day", in: "tracks") ? "multiple_entries_per_day" : "0 AS multiple_entries_per_day"
        let orderColumn = try database.containsColumn("order", in: "tracks") ? "\"order\"" : "_id AS \"order\""
        let iconColumn = try database.containsColumn("icon", in: "tracks") ? "icon" : "NULL AS icon"
        let enabledColumn = try database.containsColumn("enabled", in: "tracks") ? "enabled" : "1 AS enabled"

        let sql = """
        SELECT _id, name, \(iconColumn), \(enabledColumn), \(multipleColumn), \(colorColumn), \(orderColumn)
        FROM tracks
        ORDER BY \"order\" ASC, name ASC
        """

        return try database.query(sql) { statement in
            AndroidTrack(
                id: Int(sqlite3_column_int(statement, 0)),
                name: database.string(statement, 1) ?? "",
                icon: database.string(statement, 2),
                enabled: sqlite3_column_int(statement, 3) != 0,
                multiple: sqlite3_column_int(statement, 4) != 0,
                color: Int32(sqlite3_column_int(statement, 5)),
                index: Int16(clamping: sqlite3_column_int(statement, 6))
            )
        }
    }

    private static func readGroups(from database: Database) throws -> [AndroidGroup] {
        guard try database.containsTable("groups") else { return [] }
        let orderColumn = try database.containsColumn("order", in: "groups") ? "\"order\"" : "_id AS \"order\""

        return try database.query("SELECT _id, name, \(orderColumn) FROM groups ORDER BY \"order\" ASC, name ASC") { statement in
            AndroidGroup(
                id: Int(sqlite3_column_int(statement, 0)),
                name: database.string(statement, 1) ?? "",
                index: Int16(clamping: sqlite3_column_int(statement, 2))
            )
        }
    }

    private static func readTrackGroupRelationships(from database: Database) throws -> [Int: [Int]] {
        guard try database.containsTable("track2groups") else { return [:] }
        let rows: [(trackID: Int, groupID: Int)] = try database.query("SELECT _track_id, _group_id FROM track2groups ORDER BY _id ASC") { statement in
            (Int(sqlite3_column_int(statement, 0)), Int(sqlite3_column_int(statement, 1)))
        }
        return Dictionary(grouping: rows, by: \.trackID).mapValues { $0.map(\.groupID) }
    }

    private static func readTicks(from database: Database) throws -> [AndroidTick] {
        try database.query("SELECT _track_id, year, month, day, hour, minute, second, has_time_info FROM ticks ORDER BY year ASC, month ASC, day ASC, _id ASC") { statement in
            let year = Int(sqlite3_column_int(statement, 1))
            // Android stores Java Calendar.MONTH, which is zero-based.
            let month = Int(sqlite3_column_int(statement, 2)) + 1
            let day = Int(sqlite3_column_int(statement, 3))
            let hasTime = sqlite3_column_int(statement, 7) != 0
            let hour = hasTime ? Int(sqlite3_column_int(statement, 4)) : 0
            let minute = hasTime ? Int(sqlite3_column_int(statement, 5)) : 0
            let second = hasTime ? Int(sqlite3_column_int(statement, 6)) : 0

            var components = DateComponents()
            components.calendar = Calendar(identifier: .gregorian)
            components.timeZone = .current
            components.year = year
            components.month = month
            components.day = day
            components.hour = hour
            components.minute = minute
            components.second = second

            guard let date = components.date else {
                throw AndroidDatabaseImportError.invalidFormat
            }

            return AndroidTick(trackID: Int(sqlite3_column_int(statement, 0)), date: date)
        }
    }

    private static func isoDateString(from date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 1970, components.month ?? 1, components.day ?? 1)
    }

    private static func days(from startDate: Date, to date: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    private static func systemImage(forAndroidIcon icon: String?, trackName: String) -> String {
        let haystack = ((icon ?? "") + " " + trackName).lowercased()
        let mappings: [(String, String)] = [
            ("drink", "drop.fill"),
            ("water", "drop.fill"),
            ("coffee", "cup.and.saucer.fill"),
            ("cake", "birthday.cake.fill"),
            ("food", "fork.knife"),
            ("smok", "smoke.fill"),
            ("hospital", "cross.case.fill"),
            ("med", "pills.fill"),
            ("dumbbell", "dumbbell.fill"),
            ("sport", "figure.run"),
            ("bicycle", "bicycle"),
            ("car", "car.fill"),
            ("train", "tram.fill"),
            ("dog", "dog.fill"),
            ("flower", "camera.macro"),
            ("leaf", "leaf.fill"),
            ("piano", "music.note"),
            ("clean", "sparkles"),
            ("facebook", "person.2.fill"),
            ("email", "envelope.fill")
        ]
        return mappings.first { haystack.contains($0.0) }?.1 ?? "checkmark"
    }
}

private final class Database {
    private var handle: OpaquePointer?

    init(url: URL) throws {
        guard sqlite3_open_v2(url.path, &handle, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            let message = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "Could not open database."
            throw AndroidDatabaseImportError.sqliteError(message)
        }
    }

    func close() {
        if handle != nil {
            sqlite3_close(handle)
            handle = nil
        }
    }

    func containsTable(_ table: String) throws -> Bool {
        try scalarInt("SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = ?", bindings: [table]) > 0
    }

    func containsColumn(_ column: String, in table: String) throws -> Bool {
        let rows: [String] = try query("PRAGMA table_info(\"\(table.replacingOccurrences(of: "\"", with: "\"\""))\")") { statement in
            self.string(statement, 1) ?? ""
        }
        return rows.contains(column)
    }

    func query<T>(_ sql: String, bindings: [String] = [], map: (OpaquePointer) throws -> T) throws -> [T] {
        let statement = try prepare(sql, bindings: bindings)
        defer { sqlite3_finalize(statement) }

        var values: [T] = []
        while true {
            let result = sqlite3_step(statement)
            switch result {
            case SQLITE_ROW:
                values.append(try map(statement!))
            case SQLITE_DONE:
                return values
            default:
                throw AndroidDatabaseImportError.sqliteError(errorMessage)
            }
        }
    }

    func scalarInt(_ sql: String, bindings: [String] = []) throws -> Int {
        let rows: [Int] = try query(sql, bindings: bindings) { statement in
            Int(sqlite3_column_int(statement, 0))
        }
        return rows.first ?? 0
    }

    func string(_ statement: OpaquePointer, _ index: Int32) -> String? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL,
              let text = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: text)
    }

    private func prepare(_ sql: String, bindings: [String]) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else {
            throw AndroidDatabaseImportError.sqliteError(errorMessage)
        }
        for (index, value) in bindings.enumerated() {
            sqlite3_bind_text(statement, Int32(index + 1), value, -1, SQLITE_TRANSIENT)
        }
        return statement
    }

    private var errorMessage: String {
        handle.map { String(cString: sqlite3_errmsg($0)) } ?? "Unknown SQLite error."
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
