//
//  TrackController.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/21/21.
//

import CoreData
import SwiftUI
import SwiftDate

class TrackController: NSObject, ObservableObject {
    
    var tickControllers: [Track: TickController] = [:]
    let date = Date()
    var fetchedResultsController: NSFetchedResultsController<Track>
    
    init(preview: Bool = false) {
        let context = preview ? PersistenceController.preview.container.viewContext : PersistenceController.shared.container.viewContext
        
        let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Track.index, ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController<Track>(fetchRequest: fetchRequest,
                                                                     managedObjectContext: context,
                                                                     sectionNameKeyPath: nil,
                                                                     cacheName: nil)
        
        super.init()
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            NSLog("Error performing Tracks fetch: \(error)")
        }
    }
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
    
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current
        formatter.formatOptions = .withFullDate
        return formatter
    }()
    
    func loadTicks(for track: Track) {
        if let tickController = tickControllers[track] {
            tickController.loadTicks()
        } else {
            tickControllers[track] = TickController(track: track, trackController: self)
        }
    }
    
    func tickController(for track: Track) -> TickController {
        tickControllers[track] ?? {
            let tickController = TickController(track: track, trackController: self)
            tickControllers[track] = tickController
            return tickController
        }()
    }
    
    func dayLabel(day: Int) -> TextWithCaption {
        let date = self.date - day.days
        
        let weekday: String
        switch day {
        case 0:
            weekday = "Today"
        case 1:
            weekday = "Yesterday"
        default:
            weekday = TrackController.weekdayFormatter.string(from: date)
        }
        
        return TextWithCaption(text: weekday, caption: dateFormatter.string(from: date))
    }
    
    func newTrack(index: Int16, context moc: NSManagedObjectContext) -> Track {
        Track(name: "New Track", startDate: TrackController.iso8601.string(from: date.in(region: .current).date), index: index, context: moc)
    }
    
}

extension TrackController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        withAnimation {
            objectWillChange.send()
        }
    }
}
