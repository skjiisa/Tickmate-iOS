//
//  TickController.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/21/21.
//

import CoreData
import SwiftDate

class TickController: NSObject, ObservableObject {
    
    //MARK: Properties
    
    let track: Track
    @Published var ticks: [Tick?] = []
    private var fetchedResultsController: NSFetchedResultsController<Tick>
    weak var trackController: TrackController?
    var todayOffset: Int?
    
    init(track: Track, trackController: TrackController, observeChanges: Bool = true, preview: Bool) {
        self.track = track
        self.trackController = trackController
        
        let moc = track.managedObjectContext ?? (preview ? PersistenceController.preview : PersistenceController.shared).container.viewContext
        
        let fetchRequest: NSFetchRequest<Tick> = Tick.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "track == %@", track)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Tick.dayOffset, ascending: false),
            NSSortDescriptor(keyPath: \Tick.modified, ascending: false)
        ]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: moc,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)
        
        super.init()
        
        if observeChanges {
            fetchedResultsController.delegate = self
        }
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            NSLog("Error performing Ticks fetch for \(track.name ?? "track"): \(error)")
        }
        
        loadTicks()
    }
    
    func loadTicks() {
        guard let allTicks = fetchedResultsController.fetchedObjects,
              // Calculate today's offset
              let startDateString = track.startDate,
              let startDate = DateInRegion(startDateString, region: .current)?.dateTruncated(at: [.hour, .minute, .second]),
              let today = trackController?.date.in(region: .current).dateTruncated(at: [.hour, .minute, .second]),
              // Subtract 2 hours here to overestimate the offset to account for for any daylight savings time changes.
              // Because we're truncating at the number of days, having one or two hours extra won't increase
              // the day offset, but having one hour less because of DST would incorrectly offset the day.
              let todayOffset = (today - (startDate - 2.hours)).toUnit(.day) else { return }
        self.todayOffset = todayOffset
        
        var ticks = [Tick?]()
        var i = 0
        var changesToSave = false
        
        for day in 0..<365 {
            let offsetDay = todayOffset - day
            while i < allTicks.count,
                  allTicks[i].dayOffset > offsetDay {
                i += 1
            }
            
            guard i < allTicks.count else { break }
            
            if allTicks[i].dayOffset == offsetDay {
                ticks.append(allTicks[i])
                i += 1
                // Check for duplicates
                // Duplicates could come from multiple devices
                // ticking the same day before the CloudKit sync.
                while i < allTicks.count,
                      allTicks[i].dayOffset == offsetDay {
                    let tick = allTicks[i]
                    // Delete tick with same dayOffset. Because the FRC is sorted
                    // by dayOffset then descending modified date, the newest
                    // Tick should be first and we can delete any after it.
                    print("Duplicate found:", tick)
                    // Tag it as a duplicate so the FRC doesn't
                    // remove its day from the ticks array.
                    tick.duplicate = true
                    track.managedObjectContext?.delete(tick)
                    changesToSave = true
                    i += 1
                }
            } else {
                ticks.append(nil)
            }
        }
        
        // Since the save function already checks the context's hasChanges
        // property, this check probably doesn't need to be here, but I don't
        // want to be saving more than necissary, and this can't hurt.
        if changesToSave {
            save()
        }
        
        self.ticks = ticks
    }
    
    //MARK: Ticking
    
    func getTick(for day: Int) -> Tick? {
        guard ticks.indices.contains(day) else { return nil }
        return ticks[day]
    }
    
    func ticks(on day: Int) -> Int {
        guard let tick = getTick(for: day) else { return 0 }
        return Int(tick.count)
    }
    
    func tick(day: Int) {
        if let tick = getTick(for: day) {
            if track.multiple {
                tick.count += 1
                tick.modified = Date()
                save()
            } else {
                untick(day: day)
            }
        } else if let todayOffset = todayOffset {
            Tick(track: track, dayOffset: Int16(todayOffset - day))
            save()
        }
    }
    
    @discardableResult
    func untick(day: Int) -> Bool {
        guard let tick = getTick(for: day) else { return false }
        if tick.count < 2 {
            track.managedObjectContext?.delete(tick)
        } else {
            tick.count -= 1
            tick.modified = Date()
        }
        save()
        return true
    }
    
    //MARK: Private
    
    private func save() {
        trackController?.scheduleSave()
    }
    
    private func day(for tick: Tick) -> Int? {
        guard let todayOffset = todayOffset else { return nil }
        return todayOffset - Int(tick.dayOffset)
    }
    
    private func insert(at indexPath: IndexPath) {
        let tick = fetchedResultsController.object(at: indexPath)
        
        guard let day = day(for: tick),
              day < 365 else { return }
        while ticks.count < day + 1 {
            ticks.append(nil)
        }
        ticks[day] = tick
    }
    
    private func delete(_ object: Any, at indexPath: IndexPath) {
        guard let tick = object as? Tick,
              // Don't remove the day from the list if this
              // was just a duplicate that's being deleted.
              !tick.duplicate,
              let day = day(for: tick),
              ticks.indices.contains(day) else { return }
        ticks[day] = nil
        
        //TODO: Check for duplicates
        // Don't forget to tag them as duplicates
        // before deleting so that this function
        // doesn't run recursively on them.
    }
    
}

//MARK: Fetched Results Controller Delegate

extension TickController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        objectWillChange.send()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            insert(at: newIndexPath)
        case .delete:
            guard let indexPath = indexPath else { return }
            delete(anObject, at: indexPath)
        default:
            break
        }
    }
}
