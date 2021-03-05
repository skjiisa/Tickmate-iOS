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
    
    init(track: Track, trackController: TrackController) {
        self.track = track
        self.trackController = trackController
        
        if let startDateString = track.startDate,
           let startDate = DateInRegion(startDateString, region: .current)?.dateTruncated(at: [.hour, .minute, .second]),
           let today = trackController.date.in(region: .current).dateTruncated(at: [.hour, .minute, .second]) {
            todayOffset = (today - startDate).toUnit(.day)
        }
        
        let moc = track.managedObjectContext ?? PersistenceController.preview.container.viewContext
        let fetchRequest: NSFetchRequest<Tick> = Tick.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "track == %@", track)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Tick.dayOffset, ascending: false)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: moc,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)
        
        super.init()
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Error performing ticks fetch for \(track.name ?? "track"): \(error)")
        }
        
        loadTicks()
    }
    
    func loadTicks() {
        guard let allTicks = fetchedResultsController.fetchedObjects,
              let todayOffset = todayOffset else { return }
        
        var ticks = [Tick?]()
        var i = 0
        for day in 0..<365 {
            let offsetDay = todayOffset - day
            while i < allTicks.count,
                  allTicks[i].dayOffset > offsetDay {
                i += 1
            }
            
            if i >= allTicks.count {
                break
            }
            
            if allTicks[i].dayOffset == offsetDay {
                ticks.append(allTicks[i])
            } else {
                ticks.append(nil)
            }
        }
        
        self.ticks = ticks
        
        print(fetchedResultsController.fetchedObjects)
        print(self.ticks)
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
        }
        save()
        return true
    }
    
    //MARK: Private
    
    private func save() {
        if let moc = track.managedObjectContext,
           moc.hasChanges {
            PersistenceController.save(context: moc)
        }
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
              let day = day(for: tick),
              ticks.indices.contains(day) else { return }
        ticks[day] = nil
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
