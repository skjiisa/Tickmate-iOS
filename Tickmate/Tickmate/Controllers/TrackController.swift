//
//  TrackController.swift
//  Tickmate
//
//  Created by Elaine Lyons on 2/21/21.
//

import CoreData
import SwiftUI
import SwiftDate
#if os(iOS)
import WidgetKit
#endif

//MARK: TrackController

class TrackController: NSObject, ObservableObject {
    
    static var shared = TrackController()
    
    //MARK: Properties
    
    static let sortDescriptors = [
        NSSortDescriptor(keyPath: \Track.index, ascending: true),
        // For consistency when there are index collisions with iCloud sync
        NSSortDescriptor(keyPath: \Track.name, ascending: true),
    ]
    
    var tickControllers: [Track: TickController] = [:]
    
    var date: Date
    var weekday: Int
    @Published var weekStartDay: Int
    @Published var relativeDates: Bool
    
    // Is it ideal for this to live here? Probably not.
    // Do I care enough to make a proper place for it? No.
    private var lockedDayTapCount: Int = 0
    private var todayLockTask: Task<Void, any Error>?
    @Published var todayLockAlert: AlertItem?
    
    func didTapLockedDay() {
        todayLockTask?.cancel()
        lockedDayTapCount += 1
        if lockedDayTapCount >= 2 {
            todayLockAlert = AlertItem(
                title: "Today Lock Enabled",
                message: "To edit previous days, disable Today Lock in settings"
            )
            lockedDayTapCount = 0
        } else {
            todayLockTask = Task {
                try await Task.sleep(nanoseconds: 5 * NSEC_PER_SEC)
                lockedDayTapCount = 0
            }
        }
    }
    
    private var observeChanges: Bool
    private var preview: Bool
    private var saveWork: DispatchWorkItem?
    private var refreshWork: DispatchWorkItem?
    
    lazy var fetchedResultsController: NSFetchedResultsController<Track> = {
        let context = (preview ? PersistenceController.preview : PersistenceController.shared).container.viewContext
        
        let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
        fetchRequest.sortDescriptors = Self.sortDescriptors
        fetchRequest.predicate = NSPredicate(format: "isArchived == NO")
        
        let frc = NSFetchedResultsController<Track>(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
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
    
    lazy var archivedTracksFRC: NSFetchedResultsController<Track> = {
        let context = (preview ? PersistenceController.preview : PersistenceController.shared).container.viewContext
        
        let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
        fetchRequest.sortDescriptors = Self.sortDescriptors
        fetchRequest.predicate = NSPredicate(format: "isArchived == YES")
        
        let frc = NSFetchedResultsController<Track>(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        if observeChanges {
            frc.delegate = self
        }
        
        do {
            try frc.performFetch()
            print("TrackController archived FRC fetched.")
        } catch {
            NSLog("Error performing Tracks fetch: \(error)")
        }
        
        return frc
    }()
    
    init(observeChanges: Bool = true, preview: Bool = false) {
        self.observeChanges = observeChanges
        self.preview = preview
        
        UserDefaults.standard.register(defaults: [
            Defaults.weekStartDay.rawValue: 2,
            Defaults.relativeDates.rawValue: true
        ])
        
        TrackController.migrateUserDefaultsIfNeeded()
        
        UserDefaults(suiteName: groupID)?.register(defaults: [
            Defaults.weekStartDay.rawValue: 2
        ])
        
        date = Date() - TrackController.dayOffset
        weekday = date.in(region: .current).weekday
        
        weekStartDay = UserDefaults(suiteName: groupID)?.integer(forKey: Defaults.weekStartDay.rawValue) ?? 2
        relativeDates = UserDefaults.standard.bool(forKey: Defaults.relativeDates.rawValue)
        
        super.init()
    }
    
    //MARK: Static
    
    static var dayOffset: DateComponents {
        (UserDefaults(suiteName: groupID)?.bool(forKey: Defaults.customDayStart.rawValue) ?? false
            ? UserDefaults(suiteName: groupID)?.integer(forKey: Defaults.customDayStartMinutes.rawValue) ?? 0
            : 0).minutes
    }
    
    private static func migrateUserDefaultsIfNeeded() {
        if let userDefaults = UserDefaults(suiteName: groupID),
           !userDefaults.bool(forKey: Defaults.userDefaultsMigration.rawValue) {
            let customDayStart = Defaults.customDayStart.rawValue
            userDefaults.set(UserDefaults.standard.bool(forKey: customDayStart), forKey: customDayStart)
            
            let customDayStartMinutes = Defaults.customDayStartMinutes.rawValue
            userDefaults.set(UserDefaults.standard.integer(forKey: customDayStartMinutes), forKey: customDayStartMinutes)
            
            let weekStartDay = Defaults.weekStartDay.rawValue
            userDefaults.set(UserDefaults.standard.integer(forKey: weekStartDay), forKey: weekStartDay)
            
            userDefaults.set(true, forKey: Defaults.userDefaultsMigration.rawValue)
            print("UserDefaults migrated")
        }
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
    
    static let iso8601Full = ISO8601DateFormatter()
    
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
        
        return (weekday, dateFormatter.string(from: date))
    }
    
    func isWeekEnd(day: Int) -> Bool {
        // The Swift % operator doesn't calculate
        // the modulo from negative numbers,
        // so we're adding 7 and %ing again.
        (weekday - day % 7 + 7) % 7 + 1 == weekStartDay
    }
    
    private func isWeekStart(day: Int) -> Bool {
        (weekday - day % 7 + 6) % 7 + 1 == weekStartDay
    }
    
    func insets(day: Int) -> Edge.Set? {
        let todayAtTop = UserDefaults(suiteName: groupID)?.bool(forKey: Defaults.todayAtTop.rawValue) ?? false
        var after: Edge.Set { todayAtTop ? .top : .bottom }
        var before: Edge.Set { todayAtTop ? .bottom : .top }
        
        if isWeekEnd(day: day) {
            return after
        } else if isWeekStart(day: day) {
            return before
        } else {
            return .none
        }
    }
    
    func shouldShowSeparatorBelow(day: Int) -> Bool {
        let todayAtTop = UserDefaults(suiteName: groupID)?.bool(forKey: Defaults.todayAtTop.rawValue) ?? false
        
        if todayAtTop {
            return isWeekStart(day: day)
        } else {
            return isWeekEnd(day: day)
        }
    }
    
    //MARK: Track CRUD
    
    func newTrack(index: Int16, context moc: NSManagedObjectContext) -> Track {
        objectWillChange.send()
        return Track(name: "New Track", startDate: TrackController.iso8601.string(from: date.in(region: .current).date), index: index, context: moc)
    }
    
    @discardableResult
    func newTrack(from representation: TrackRepresentation, index: Int16, context moc: NSManagedObjectContext) -> Track {
        objectWillChange.send()
        let track = Track(name: "", startDate: TrackController.iso8601.string(from: date.in(region: .current).date), index: index, context: moc)
        representation.save(to: track)
        PersistenceController.save(context: moc)
        return track
    }
    
    func delete(track: Track, context moc: NSManagedObjectContext) {
        // When deleting a track programmatically, call trackController.objectWillChange.send()
        // before calling this. If deleting a track from a List, don't call that.
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
        scheduleTimelineRefresh()
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
        if UserDefaults(suiteName: groupID)?.bool(forKey: Defaults.customDayStart.rawValue) ?? false {
            minutes = givenMinutes
            UserDefaults(suiteName: groupID)?.setValue(minutes, forKey: Defaults.customDayStartMinutes.rawValue)
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
            scheduleTimelineRefresh()
        }
    }
    
    // TODO: Update this and the below to instead save _now_, but prevent a second save from happening for 5 seconds (or whatever interval)
    /// Schedule a Core Data save on the current view context.
    ///
    /// Call this function when you want to save a small change when other small changes may happen soon after.
    /// This will wait 5 seconds before saving, ignoring later calls until the 5 seconds have passed.
    /// As a result, this will only save up to once every 5 seconds in order to prevent heavy disk usage from frequent calls.
    func scheduleSave() {
        guard saveWork == nil else { return }
        
        let work = DispatchWorkItem { [weak self] in
            self?.saveWork = nil
            guard let context = self?.fetchedResultsController.managedObjectContext else { return }
            PersistenceController.save(context: context)
            self?.setLastUpdateTime()
            print("Saved")
        }
        saveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: work)
    }
    
    func scheduleTimelineRefresh() {
        guard refreshWork == nil else { return }
        let work = DispatchWorkItem { [weak self] in
            self?.refreshWork = nil
            #if os(iOS)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
            print("Widget timelines reloaded")
        }
        refreshWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: work)
    }
    
    func setLastUpdateTime() {
        UserDefaults(suiteName: groupID)?.set(TrackController.iso8601Full.string(from: Date()), forKey: Defaults.lastUpdateTime.rawValue)
    }
    
    /// This will shortcut the 5-second wait from `scheduleSave()`.
    /// If no save has been scheduled, it will do nothing.
    func saveIfScheduled() {
        saveWork?.perform()
        refreshWork?.perform()
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
            scheduleTimelineRefresh()
            print("Updated from \(oldDate) to \(newDate)")
        }
    }
    
}

//MARK: Fetched Results Controller Delegate

extension TrackController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        objectWillChange.send()
    }
    /*
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard [.delete, .insert].contains(type) else { return }
        
        var indices = Set<Int16>()
        let hasDuplicateIndices = fetchedResultsController.fetchedObjects?.contains { item in
            indices.insert(item.index).inserted
        } ?? false
        
        guard hasDuplicateIndices else { return }
        
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
        saveIfScheduled()
    }
     */
}
