//
//  Persistence.swift
//  Tickmate
//
//  Created by Elaine Lyons on 2/19/21.
//

import SwiftUI
import CoreData
import SwiftDate

class PersistenceController {
    
    //MARK: Static instances
    
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        let group = TrackGroup(name: "Test group", index: 0, context: viewContext)
        result.previewGroup = group
        
        let dateString = TrackController.iso8601.string(from: Date() - 5.days)
        for i: Int16 in 0..<6 {
            let track = Track(
                name: String(UUID().uuidString.dropLast(28)),
                multiple: 1...2 ~= i,
                reversed: i == 2,
                startDate: dateString,
                index: i,
                isArchived: i == 5,
                context: viewContext
            )
            
            if i == 1 {
                for day in 0..<5 {
                    let count = Int16.random(in: 0..<4)
                    if count > 0 {
                        let tick = Tick(track: track, dayOffset: Int16(day), context: viewContext)
                        tick.count = count
                    }
                }
            } else {
                for day in 0..<5 where Bool.random() {
                    Tick(track: track, dayOffset: Int16(day))
                }
                track.groups = [group]
            }
        }
        result.save()
        return result
    }()
    
    //MARK: Demo
    
    #if DEBUG
    func loadDemo() -> PersistenceController {
        let viewContext = container.viewContext
        
        // Only create demo data if there is not already data
        let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
        fetchRequest.fetchLimit = 1
        guard (try? viewContext.fetch(fetchRequest))?.isEmpty ?? false else { return self }
        print("Loading demo...")
        
        let startDateOffset = 14
        let dateString = TrackController.iso8601.string(from: Date() - startDateOffset.days)
        
        // Demo Groups
        
        // Unlock the groups in-app-purchase
        UserDefaults.standard.set(true, forKey: StoreController.Products.groups.rawValue)
        let daily = TrackGroup(name: "Daily", index: 0, context: viewContext)
        let occasional = TrackGroup(name: "Occasional", index: 1, context: viewContext)
        let group3 = TrackGroup(name: "Group 3", index: 2, context: viewContext)
        
        UserDefaults.standard.set(false, forKey: Defaults.showAllTracks.rawValue)
        
        // Daily Tracks
        
        let dailyTracks = [
            [true, true, true, false, true, true, true, true, true, true, false, true, false, true, true, true, true, false, false, false, false, true, true, false],
            [false, true, true, true, true, true, true, true, true, true, true, false, true, false, true, true, true, false, true, true, true, true, true, false],
            [true, true, true, false, true, false, false, true, false, true, false, true, false, true, false].map { !$0 },   // This one is reversed
            [true, true, true, true, true, false, true, true, false, true, false, true, true, true, true, true, false, true, true, true, true, true, true, true]
        ]
        
        for (i, ticks) in dailyTracks.enumerated() {
            let track = Track(
                name: String(UUID().uuidString.dropLast(28)),
                multiple: i > 0,
                reversed: i == 2,
                startDate: dateString,
                index: Int16(i),
                context: viewContext)
            PresetTracks[0].tracks[i].save(to: track)
            track.startDate = dateString
            track.addToGroups(daily)
            
            if i == 0 {
                track.addToGroups(group3)
            }
            
            for (j, tick) in ticks.enumerated() where tick {
                Tick(track: track, dayOffset: Int16(startDateOffset - j), context: viewContext)
            }
        }
        
        // Disabled Track
        
        let disabledTrack = Track(
            name: String(UUID().uuidString.dropLast(28)),
            multiple: false,
            reversed: false,
            startDate: dateString,
            index: 4,
            context: viewContext)
        PresetTracks[0].tracks[5].save(to: disabledTrack)
        disabledTrack.enabled = false
        
        // Occasional Tracks
        
        let occasionalTracks = [
            (0, [1, 8, 15, 22, 29]),
            (3, [0, 2, 3, 5, 7, 9, 10, 12, 14, 16, 17, 19, 21, 23, 24, 26, 28]),
            (1, [7, 14, 21, 28]),
            (4, [14])
        ]
        
        for (i, (index, ticks)) in occasionalTracks.enumerated() {
            let track = Track(
                name: "",
                startDate: dateString,
                index: Int16(i + dailyTracks.count),
                context: viewContext)
            PresetTracks[1].tracks[index].save(to: track)
            track.startDate = dateString
            track.addToGroups(occasional)
            
            if index == 3 {
                let reference = PresetTracks[1].tracks[2]
                track.name = reference.name
                track.systemImage = reference.systemImage
            }
            
            if index > 2 {
                track.addToGroups(group3)
            }
            
            for tick in ticks {
                Tick(track: track, dayOffset: Int16(startDateOffset - tick), context: viewContext)
            }
        }
        
        save()
        return self
    }
    #endif
    
    //MARK: Properties

    let container: NSPersistentCloudKitContainer
    
    // Preview content
    var previewGroup: TrackGroup?

    init(inMemory: Bool = false) {
        let container = NSPersistentCloudKitContainer(name: "Tickmate")
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            container.loadPersistentStores { storeDescription, error in
                if error != nil {
                    fatalError()
                }
            }
        } else {
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)!.appendingPathComponent("Tickmate.sqlite")
            
            let oldURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("Tickmate.sqlite")
            UserDefaults.standard.register(defaults: [Defaults.appGroupDatabaseMigration.rawValue: false])
            var needsMigration = !UserDefaults.standard.bool(forKey: Defaults.appGroupDatabaseMigration.rawValue)
            if needsMigration,
               let oldURL = oldURL,
               !FileManager.default.fileExists(atPath: oldURL.path) {
                print("New app install. No persistent store migration required.")
                UserDefaults.standard.set(true, forKey: Defaults.appGroupDatabaseMigration.rawValue)
                needsMigration = false
            }
            
            // Load the current persistent store
            if !needsMigration {
                container.persistentStoreDescriptions.first?.url = appGroupURL
            }
            
            container.loadPersistentStores { storeDescription, error in
                if let error = error {
                    fatalError("Unresolved error \(error)")
                }
                print("Loaded persistent store", storeDescription)
                
                if needsMigration {
                    // Perform the migration on the main thread
                    DispatchQueue.main.async {
                        do {
                            let coordinator = container.persistentStoreCoordinator
                            if let oldURL = oldURL,
                               let oldStore = coordinator.persistentStore(for: oldURL) {
                                print("Attemping to migrate persistent store from", oldURL, "to", appGroupURL)
                                try coordinator.migratePersistentStore(oldStore, to: appGroupURL, options: nil, withType: NSSQLiteStoreType)
                            }
                            
                            print("Migration complete.")
                            UserDefaults.standard.set(true, forKey: Defaults.appGroupDatabaseMigration.rawValue)
                        } catch {
                            NSLog("Unable to migrate persistent store: \(error)")
                        }
                    }
                }
            }
        }
        self.container = container
    }
    
    //MARK: Saving
    
    /// Saves the container's viewContext if there are changes.
    func save() {
        PersistenceController.save(context: container.viewContext)
    }
    
    /// Saves the given context if there are changes.
    /// - Parameter context: The Core Data context to save.
    static func save(context moc: NSManagedObjectContext) {
        guard moc.hasChanges else { return }
        do {
            try moc.save()
        } catch {
            let nsError = error as NSError
            NSLog("Error saving context: \(nsError), \(nsError.userInfo)")
        }
    }
}
