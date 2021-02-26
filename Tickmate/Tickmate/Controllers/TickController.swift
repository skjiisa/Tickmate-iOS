//
//  TickController.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/21/21.
//

import CoreData
import SwiftDate

class TickController: NSObject, ObservableObject {
    
    let track: Track
    @Published var ticks: [[Tick]] = []
    private var fetchedResultsController: NSFetchedResultsController<Tick>
    
    init(track: Track) {
        self.track = track
        
        let moc = track.managedObjectContext ?? PersistenceController.preview.container.viewContext
        let fetchRequest: NSFetchRequest<Tick> = Tick.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "track == %@", track)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Tick.timestamp, ascending: false)]
        
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
        guard let ticks = fetchedResultsController.fetchedObjects,
              let today = Date().dateTruncated([.hour, .minute, .second]) else { return }
        
        var tickDays: [(day: Int, tick: Tick)] = []
        
        for tick in ticks {
            guard let timestamp = tick.timestamp?.dateTruncated([.hour, .minute, .second]),
                  let timestampDays = (today - timestamp).day else { continue }
            let days = timestampDays + Int(tick.dayOffset)
            guard days < 365 else { break }
            tickDays.append((days, tick))
        }
        
        tickDays.sort { $0.day <= $1.day }
        
        var days: [[Tick]] = []
        var i = 0
        
        for day in 0..<365 {
            var dayTicks = [Tick]()
            while i < tickDays.count,
                  tickDays[i].day == day {
                dayTicks.append(tickDays[i].tick)
                i += 1
            }
            
            days.append(dayTicks)
            
            guard i < tickDays.count else { break }
        }
        
        self.ticks = days
        print(self.ticks)
    }
    
    func ticks(on day: Int) -> [Tick] {
        guard ticks.indices.contains(day) else { return [] }
        return ticks[day]
    }
    
    func tick(day: Int) {
        if ticks(on: day).isEmpty || track.multiple {
            Tick(track: track, dayOffset: Int16(day))
            if let moc = track.managedObjectContext {
                PersistenceController.save(context: moc)
            }
        } else {
            untick(day: day)
        }
    }
    
    func untick(day: Int) {
        guard let tick = ticks(on: day).last else { return }
        ticks[day].removeLast()
        track.managedObjectContext?.delete(tick)
    }
    
    private func insert(at indexPath: IndexPath) {
        let tick = fetchedResultsController.object(at: indexPath)
        
        guard let timestamp = tick.timestamp?.dateTruncated([.hour, .minute, .second]),
              let today = Date().dateTruncated([.hour, .minute, .second]),
              let timestampDays = (today - timestamp).day else { return }
        let day = timestampDays + Int(tick.dayOffset)
        
        guard day < 365 else { return }
        while ticks.count < day + 1 {
            ticks.append([])
        }
        ticks[day].append(tick)
    }
    
}

extension TickController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            insert(at: newIndexPath)
        case .delete: break
        case .move: break
        case .update: break
        default:
            break
        }
    }
}
