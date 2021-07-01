//
//  TrackController.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/21/21.
//

import CoreData
import SwiftUI
import SwiftDate

//MARK: TrackController

class TrackController: NSObject, ObservableObject {
    
    //MARK: Properties
    
    var tickControllers: [Track: TickController] = [:]
    
    var date: Date
    var weekday: Int
    @Published var weekStartDay: Int
    @Published var relativeDates: Bool
    
    private var observeChanges: Bool
    private var preview: Bool
    private var work: DispatchWorkItem?
    
    lazy var fetchedResultsController: NSFetchedResultsController<Track> = {
        let context = (preview ? PersistenceController.preview : PersistenceController.shared).container.viewContext
        
        let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Track.index, ascending: true)]
        
        let frc = NSFetchedResultsController<Track>(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        if observeChanges {
            frc.delegate = self
        }
        
        do {
            try frc.performFetch()
            print("TrackController FRC fetched.")
        } catch {
            NSLog("Error performing Tracks fetch: \(error)")
        }
        
        return frc
    }()
    
    init(observeChanges: Bool = true, preview: Bool = false) {
        self.observeChanges = observeChanges
        self.preview = preview
        
        UserDefaults.standard.register(defaults: [
            Defaults.customDayStartMinutes.rawValue: 0,
            Defaults.weekStartDay.rawValue: 2,
            Defaults.relativeDates.rawValue: true
        ])
        
        date = Date() - TrackController.dayOffset
        weekday = date.in(region: .current).weekday
        
        weekStartDay = UserDefaults.standard.integer(forKey: Defaults.weekStartDay.rawValue)
        relativeDates = UserDefaults.standard.bool(forKey: Defaults.relativeDates.rawValue)
        
        super.init()
    }
    
    static var dayOffset: DateComponents {
        (UserDefaults.standard.bool(forKey: Defaults.customDayStart.rawValue) ? UserDefaults.standard.integer(forKey: Defaults.customDayStartMinutes.rawValue) : 0).minutes
    }
    
    //MARK: Date Formatters
    
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
    
    //MARK: Ticks
    
    func loadTicks(for track: Track) {
        if let tickController = tickControllers[track] {
            tickController.loadTicks()
        } else {
            tickControllers[track] = TickController(track: track, trackController: self, observeChanges: observeChanges, preview: preview)
        }
    }
    
    func tickController(for track: Track) -> TickController {
        tickControllers[track] ?? {
            let tickController = TickController(track: track, trackController: self, observeChanges: observeChanges, preview: preview)
            tickControllers[track] = tickController
            return tickController
        }()
    }
    
    //MARK: Labels
    
    func dayLabel(day: Int, compact: Bool) -> (text: String, caption: String) {
        let date = self.date - day.days
        
        let weekday: String
        switch day {
        case 0 where !compact && relativeDates:
            weekday = "Today"
        case 1 where !compact && relativeDates:
            weekday = "Yesterday"
        default:
            weekday = TrackController.weekdayFormatter.string(from: date)
        }
        
//        return TextWithCaption(text: weekday, caption: dateFormatter.string(from: date))
        return (weekday, dateFormatter.string(from: date))
    }
    
    func weekend(day: Int) -> Bool {
        // The Swift % operator doesn't calculate
        // the modulo from negative numbers,
        // so we're adding 7 and %ing again.
        (weekday - day % 7 + 7) % 7 + 1 == weekStartDay
    }
    
    func insets(day: Int) -> Edge.Set? {
        weekend(day: day)
            ? .bottom
            : (weekday - day % 7 + 6) % 7 + 1 == weekStartDay
            ? .top : nil
    }
    
    //MARK: Track CRUD
    
    func newTrack(index: Int16, context moc: NSManagedObjectContext) -> Track {
        Track(name: "New Track", startDate: TrackController.iso8601.string(from: date.in(region: .current).date), index: index, context: moc)
    }
    
    @discardableResult
    func newTrack(from representation: TrackRepresentation, index: Int16, context moc: NSManagedObjectContext) -> Track {
        let track = Track(name: "", startDate: TrackController.iso8601.string(from: date.in(region: .current).date), index: index, context: moc)
        representation.save(to: track)
        PersistenceController.save(context: moc)
        return track
    }
    
    func delete(track: Track, context moc: NSManagedObjectContext) {
        tickControllers.removeValue(forKey: track)
        if let ticks = track.ticks as? Set<NSManagedObject> {
            ticks.forEach(moc.delete)
        }
        moc.delete(track)
    }
    
    func save(_ trackRepresentation: TrackRepresentation, to track: Track, context moc: NSManagedObjectContext) {
        let oldStartDate = track.startDate
        trackRepresentation.save(to: track)
        if track.startDate != oldStartDate {
            // The start date changed
            updateTickDateOffsets(for: track, oldStartString: oldStartDate)
            loadTicks(for: track)
        }
        PersistenceController.save(context: moc)
    }
    
    func updateTickDateOffsets(for track: Track, oldStartString: String?) {
        guard let oldStartString = oldStartString,
              let newStartString = track.startDate,
              let oldStartDate = DateInRegion(oldStartString, region: .current),
              let newStartDate = DateInRegion(newStartString, region: .current) else { return }
        let calculatedOffset: Int?
        if oldStartDate > newStartDate {
            calculatedOffset = (oldStartDate - (newStartDate - 2.hours)).toUnit(.day)
        } else {
            calculatedOffset = ((oldStartDate - 2.hours) - newStartDate).toUnit(.day)
        }
        
        guard let intOffset = calculatedOffset,
              let ticks = track.ticks as? Set<Tick> else { return }
        let offset = Int16(intOffset)
        ticks.forEach { $0.dayOffset += offset }
    }
    
    //MARK: Settings
    
    func setCustomDayStart(minutes givenMinutes: Int) {
        let minutes: Int
        if UserDefaults.standard.bool(forKey: Defaults.customDayStart.rawValue) {
            minutes = givenMinutes
            UserDefaults.standard.setValue(minutes, forKey: Defaults.customDayStartMinutes.rawValue)
        } else {
            // Clear the offset if customDayStart is off
            minutes = 0
        }
        
        let oldDate = date
        date = Date() - minutes.minutes
        weekday = date.in(region: .current).weekday
        
        // Check if the custom start date changed and the day needs to be updated
        if oldDate.in(region: .current).dateComponents.day != date.in(region: .current).dateComponents.day {
            objectWillChange.send()
            // This could be done more intelligently by adding or removing a day at
            // the start or the end, but this is simple and should be a fine solution.
            // You might think doing it that way would animate TicksView nicely, but it
            // actually wouldn't make a difference because it displays its days based on
            // their date relative to today, regardless of the content of the TickControllers.
            tickControllers.values.forEach { $0.loadTicks() }
        }
    }
    
    /// Schedule a Core Data save on the current view context.
    ///
    /// Call this function when you want to save a small change when other small changes may happen soon after.
    /// This will delay the save by 3 seconds and only save once if called multiple times.
    /// - Parameter now: Setting this parameter to `true` will shortcut the schedule, if there is one, and save immediatly.
    /// If there is no scheduled save, this function will do nothing instead.
    func scheduleSave(now: Bool = false) {
        guard !now else {
            if let work = work {
                work.perform()
                work.cancel()
            }
            return
        }
        
        work?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.work = nil
            guard let context = self?.fetchedResultsController.managedObjectContext else { return }
            PersistenceController.save(context: context)
            print("Saved")
        }
        self.work = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)
    }
    
    func checkForNewDay() {
        // The new date check was done differently in setCustomDayStart, but this works
        // too and I don't know if one ways is necissarily better than the other.
        let oldDate = TrackController.iso8601.string(from: date)
        let newDate = TrackController.iso8601.string(from: Date() - TrackController.dayOffset)
        if oldDate != newDate {
            objectWillChange.send()
            date = Date() - TrackController.dayOffset
            weekday = date.in(region: .current).weekday
            tickControllers.values.forEach { $0.loadTicks() }
            print("Updated from \(oldDate) to \(newDate)")
        }
    }
    
}

//MARK: Fetched Results Controller Delegate

extension TrackController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        withAnimation {
            objectWillChange.send()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard [.delete, .insert].contains(type) else { return }
        
        // Update Track indices
        var changed = false
        fetchedResultsController.fetchedObjects?.enumerated().forEach { index, item in
            let index = Int16(index)
            // Only write the index if it's different. Writing the same value in
            // will still count as a change and run this delegate function again.
            if item.index != index {
                item.index = index
                changed = true
            }
        }
        
        if changed {
            scheduleSave()
        }
        // This will only save if there is one scheduled
        scheduleSave(now: true)
    }
}
