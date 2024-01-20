//
//  GroupController.swift
//  Tickmate
//
//  Created by Elaine Lyons on 5/26/21.
//

import CoreData
import SwiftUI

class GroupController: NSObject, ObservableObject {
    
    static let sortDescriptors = [
        NSSortDescriptor(keyPath: \TrackGroup.index, ascending: true),
        // For consistency when there are index collisions with iCloud sync
        NSSortDescriptor(keyPath: \TrackGroup.name, ascending: true),
    ]
    
    var fetchedResultsController: NSFetchedResultsController<TrackGroup>
    var trackController: TrackController?
    var animateNextChange = false
    
    init(preview: Bool = false) {
        let context = (preview ? PersistenceController.preview : PersistenceController.shared).container.viewContext
        
        let fetchRequest: NSFetchRequest<TrackGroup> = TrackGroup.fetchRequest()
        fetchRequest.sortDescriptors = Self.sortDescriptors
        
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
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // TODO: This is weird
        // I feel like I remember having some bugginess when having this in a
        // withAnimation all the time, so I did this to be safe. To be fair,
        // that would've also been when I was using the awful index collision
        // resolution below, so those could've been related.
        if animateNextChange {
            withAnimation {
                objectWillChange.send()
            }
            animateNextChange = false
        } else {
            objectWillChange.send()
        }
    }
    /*
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
     */
}
