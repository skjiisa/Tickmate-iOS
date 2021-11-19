//
//  TickController.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/21/21.
//

import CoreData
import CloudKit
import SwiftDate
import SwiftUI

class TickController: NSObject, ObservableObject {
    
    //MARK: Properties
    
    let track: Track
    @Published var ticks: [Tick?] = []
    /// The tick count for a given day as fetche with `loadCKTicks` for new days that aren't already in `ticks`.
    @Published var ckTicks: [Int16?]?
    private var fetchedResultsController: NSFetchedResultsController<Tick>
    weak var trackController: TrackController?
    var todayOffset: Int?
    
    @Published var color: Color
    
    private var preview: Bool
    private var observeChanges: Bool
    
    init(track: Track, trackController: TrackController, observeChanges: Bool = true, preview: Bool) {
        self.track = track
        self.trackController = trackController
        
        color = Color(rgb: Int(track.color))
        
        self.preview = preview
        self.observeChanges = observeChanges
        
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
    
    func setTodayOffset() -> Int? {
        guard let startDateString = track.startDate,
              let startDate = DateInRegion(startDateString, region: .current)?.dateTruncated(at: [.hour, .minute, .second]),
              let today = trackController?.date.in(region: .current).dateTruncated(at: [.hour, .minute, .second]),
              // Subtract 2 hours here to overestimate the offset to account for for any daylight savings time changes.
              // Because we're truncating at the number of days, having one or two hours extra won't increase
              // the day offset, but having one hour less because of DST would incorrectly offset the day.
              let todayOffset = (today - (startDate - 2.hours)).toUnit(.day) else { return nil }
        self.todayOffset = todayOffset
        return todayOffset
    }
    
    func loadTicks() {
        guard let allTicks = fetchedResultsController.fetchedObjects,
              let todayOffset = setTodayOffset() else { return }
        
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
    
    /// Fetch `CKRecord`s for the `Tick`s for this `Track` and save them to `ckTicks`.
    ///
    /// Enters the tick count for each day into `ckTicks`.
    /// Only works when `observeChanges` is `false`, such as
    /// while the app runs in the background or in an extension, like the widget extension.
    /// - Parameter completion: runs on the main thread after the fetched ticks have been assigned to `ckTicks`.
    func loadCKTicks(completion: @escaping () -> Void = {}) {
        print("loadCKTicks", track.name ?? "")
        let container = (preview ? PersistenceController.preview : PersistenceController.shared).container
        guard let trackID = container.recordID(for: track.objectID)?.recordName,
              let todayOffset = setTodayOffset(),
              // Don't load CloudKit Ticks unless fetching for an app extension
              !observeChanges else { return completion() }
        
        let predicate = NSPredicate(format: "CD_track == %@", trackID)
        let query = CKQuery(recordType: "CD_Tick", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "CD_dayOffset", ascending: false)]
        
        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = ["CD_dayOffset", "CD_count"]
        operation.resultsLimit = 20
        
        var ckTicks = [Int16?]()
        
        operation.recordFetchedBlock = { record in
            guard let dayOffset = (record["CD_dayOffset"] as? NSNumber)?.intValue else { return }
            let day = todayOffset - dayOffset
            guard day >= 0 && day < 365 else { return }
            
            while ckTicks.count <= day {
                ckTicks.append(nil)
            }
            ckTicks[day] = (record["CD_count"] as? NSNumber)?.int16Value ?? 1
        }
        
        operation.queryCompletionBlock = { [weak self] _, error in
            if let error = error {
                NSLog("\(error)")
            }
            DispatchQueue.main.async {
                self?.ckTicks = ckTicks
                print("Done fetching CloudKit Ticks for", self?.track.name ?? "track", ckTicks)
                completion()
            }
        }
        
        // The identifier needs to be specified for when this runs in an app extension.
        CKContainer(identifier: "iCloud.vc.isv.Tickmate").privateCloudDatabase.add(operation)
    }
    
    //MARK: Ticking
    
    func tickCount(for day: Int) -> Int16 {
        // If CloudKit Ticks have been loaded, show those
        if let ckTicks = ckTicks {
            guard ckTicks.indices.contains(day) else { return 0 }
            return ckTicks[day] ?? 0
        }
        
        return getTick(for: day)?.count ?? 0
    }
    
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
        
        // This is done here as opposed to in the tick(day:)
        // function so that the timeline will alse be
        // refreshed on changes fetched from CloudKit.
        trackController?.scheduleTimelineRefresh()
    }
}
