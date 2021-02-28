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
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<3 {
            let track = Track(context: viewContext)
            track.name = UUID().uuidString
            track.color = Int32(Color(hue: Double.random(in: 0...1), saturation: 1, brightness: 1).rgb)
            track.systemImage = SymbolsList.randomElement()
            
            for day in 0..<5 {
                if Bool.random() {
                    let tick = Tick(track: track, dayOffset: 0)
                    if day == 4 {
                        tick?.timestamp = Date()
                        tick?.dayOffset = Int16(day)
                    } else {
                        tick?.timestamp = Date() - day.days
                    }
                }
            }
        }
        result.save()
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Tickmate")
        container.viewContext.automaticallyMergesChangesFromParent = true
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else if let description = container.persistentStoreDescriptions.first {
            description.setOption(true as NSObject, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(processUpdate), name: .NSPersistentStoreRemoteChange, object: self.container)
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
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    //MARK: Merging changes
    
    // Based on SchwiftUI's demo
    // https://schwiftyui.com/swiftui/using-cloudkit-in-swiftui/
    // https://github.com/SchwiftyUI/OrderedList/blob/master/OrderedList/AppDelegate.swift
    
    lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    @objc
    private func processUpdate(notification: Notification) {
        
    }
}
