//
//  GroupController.swift
//  Tickmate
//
//  Created by Elaine Lyons on 5/26/21.
//

import CoreData
import SwiftUI

class GroupController: NSObject, ObservableObject {
    
    static var shared = GroupController()
    
    var fetchedResultsController: NSFetchedResultsController<TrackGroup>
    var trackController: TrackController?
    
    init(preview: Bool = false) {
        let context = (preview ? PersistenceController.preview : PersistenceController.shared).container.viewContext
        
        let fetchRequest: NSFetchRequest<TrackGroup> = TrackGroup.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TrackGroup.index, ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController<TrackGroup>(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        super.init()
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            NSLog("Error performing TrackGroups fetch: \(error)")
        }
    }
}

extension GroupController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard [.delete, .insert].contains(type) else { return }
        
        var changed = false
        
        // Update indices
        fetchedResultsController.fetchedObjects?.enumerated()
            .map({ (Int16($0), $1) })
            .filter({ $0 != $1.index })
            .forEach { index, item in
                item.index = index
                changed = true
            }
        
        if changed {
            trackController?.scheduleSave()
        }
        trackController?.saveIfScheduled()
    }
}
