//
//  Persistence.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/19/21.
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
        for i: Int16 in 0..<3 {
            let track = Track(
                name: String(UUID().uuidString.dropLast(28)),
                multiple: i > 0,
                reversed: i == 2,
                startDate: dateString,
                index: i,
                context: viewContext)
            
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
    
    func loadDemo() -> PersistenceController {
        let viewContext = container.viewContext
        
        let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
        fetchRequest.fetchLimit = 1
        guard (try? viewContext.fetch(fetchRequest))?.isEmpty ?? false else { return self }
        print("Loading demo...")
        
        let startDateOffset = 14
        let dateString = TrackController.iso8601.string(from: Date() - startDateOffset.days)
        
        let demoTracks = [
            [true, true, true, false, true, true, true, true, true, true, false, true, false, true, true, true, true, false, false, false, false, true, true, false],
            [false, true, true, true, true, true, true, true, true, true, true, false, true, false, true, true, true, false, true, true, true, true, true, false],
            [true, true, true, false, true, false, false, true, false, true, false, true, false, true, false].map { !$0 },   // This one is reversed
            [true, true, true, true, true, false, true, true, false, true, false, true, true, true, true, true, false, true, true, true, true, true, true, true]
        ]
        
        for (i, ticks) in demoTracks.enumerated() {
            let track = Track(
                name: String(UUID().uuidString.dropLast(28)),
                multiple: i > 0,
                reversed: i == 2,
                startDate: dateString,
                index: Int16(i),
                context: viewContext)
            PresetTracks[0].tracks[i].save(to: track)
            track.startDate = dateString
            
            for (j, tick) in ticks.enumerated() where tick {
                Tick(track: track, dayOffset: Int16(startDateOffset - j), context: viewContext)
            }
        }
        
        let disabledTrack = Track(
            name: String(UUID().uuidString.dropLast(28)),
            multiple: false,
            reversed: false,
            startDate: dateString,
            index: 4,
            context: viewContext)
        PresetTracks[0].tracks[5].save(to: disabledTrack)
        disabledTrack.enabled = false
        
        save()
        return self
    }
    
    //MARK: Properties

    let container: NSPersistentCloudKitContainer
    
    // Preview content
    var previewGroup: TrackGroup?

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Tickmate")
        container.viewContext.automaticallyMergesChangesFromParent = true
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                Typical reasons for an error here include:
                * The parent directory does not exist, cannot be created, or disallows writing.
                * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                * The device is out of space.
                * The store could not be migrated to the current model version.
                Check the error message to determine what the actual problem was.
                */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
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
