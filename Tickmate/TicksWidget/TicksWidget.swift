//
//  TicksWidget.swift
//  TicksWidget
//
//  Created by Elaine Lyons on 6/23/21.
//

import WidgetKit
import SwiftUI
import Intents
import CoreData
import SwiftDate

//MARK: - Provider

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> TracksEntry {
        TracksEntry(date: Date(), configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (TracksEntry) -> ()) {
        let tracks = tracks(for: configuration, context: PersistenceController.shared.container.viewContext) ?? []
        let entry = TracksEntry(date: Date(), configuration: configuration, tracks: tracks)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [TracksEntry] = []
        
        // Fetch Tracks
        let tracks = tracks(for: configuration, context: PersistenceController.shared.container.viewContext) ?? []
        
        let trackController = TrackController(observeChanges: false)
        
        entries.append(Entry(date: Date(), configuration: configuration, controller: trackController, tracks: tracks))
        
        // To test refreshes, you can adjust this entry to be much sooner, like 15 seconds.
        // Just make sure you only run the widget connected to the debugger like that and don't
        // leave it on your home screen after you disconnect.
        
        var nextEntryDate = Date() + 30.minutes
        let offsetEntryDate = nextEntryDate - TrackController.dayOffset
        
        let currentDate = TrackController.iso8601.string(from: Date() - TrackController.dayOffset)
        let newDate = TrackController.iso8601.string(from: offsetEntryDate)
        if currentDate != newDate {
            // The new day rollover is less than 30 minutes from now.
            // Add a new timeline entry right at the new day rollover.
            nextEntryDate = offsetEntryDate.dateAtStartOf([.day]) + TrackController.dayOffset
            
            print(offsetEntryDate.dateAtStartOf([.day]) + TrackController.dayOffset)
        }
        
        entries.append(Entry(date: nextEntryDate, configuration: configuration, controller: trackController, tracks: tracks))

        let timeline = Timeline(entries: entries, policy: .atEnd)
        
        // Check last sync time
        let lastSyncSeconds: Int
                
        if let lastUpdateTimeString = UserDefaults(suiteName: groupID)?.string(forKey: Defaults.lastUpdateTime.rawValue),
           let lastUpdateTime = TrackController.iso8601Full.date(from: lastUpdateTimeString),
           let difference = Date().difference(in: .second, from: lastUpdateTime) {
            lastSyncSeconds = difference
        } else {
            lastSyncSeconds = 0
        }
        
        print("!!!!!!!!!!!!Difference", lastSyncSeconds)
        
        // Refreshes of the widget will only check for changes from CloudKit
        // if the last update was more than 29 minutes in the past.
        // You can lower this value during testing to test CloudKit fetches.
        if lastSyncSeconds > 60 * 29 {
            // Download updated data from CloudKit
            DispatchQueue.global(qos: .background).async {
                let dispatchGroup = DispatchGroup()
                
                tracks.forEach { track in
                    dispatchGroup.enter()
                    trackController.tickController(for: track).loadCKTicks(completion: dispatchGroup.leave)
                }
                
                _ = dispatchGroup.wait(timeout: .now() + 20)
                trackController.setLastUpdateTime()
                completion(timeline)
            }
        } else {
            // The last update was recent enough,
            // so don't bother checking CloudKit.
            completion(timeline)
        }
    }
    
    //MARK: Helpers
    
    private func tracks(for configuration: ConfigurationIntent, context moc: NSManagedObjectContext) -> [Track]? {
        // This isn't using a switch statement because chaining ??? operators allows it to fall
        // back to the default fetch request if the results are nil, OR if they're empty.
        (configuration.tracksMode == .choose
         ? configuration.tracks?.prefix(8)
            .compactMap { object(for: $0, context: moc) }
            .sorted(by: { $0.index < $1.index })
         : nil)
        ??? (configuration.tracksMode == .group ? getTracks(for: configuration.group, context: moc) : nil)
        ??? automaticFetch(context: moc)
    }
    
    private func object<T: NSManagedObject>(for inObject: INObject, context moc: NSManagedObjectContext) -> T? {
        guard let idString = inObject.identifier,
              let url = URL(string: idString),
              let id =
                moc.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url)  else { return nil }
        return moc.object(with: id) as? T
    }
    
    private func automaticFetch(context moc: NSManagedObjectContext) -> [Track]? {
        let groupFetchRequest: NSFetchRequest<TrackGroup> = TrackGroup.fetchRequest()
        groupFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TrackGroup.index, ascending: true)]
        groupFetchRequest.fetchLimit = 1
        
        var tracks: [Track]?
        
        // If the user has a group, show tracks from that group
        if let group = (try? moc.fetch(groupFetchRequest))?.first {
            tracks = getTracks(for: group, context: moc)
        }
        
        return tracks ??? (try? moc.fetch(tracksFetchRequest()))
    }
    
    private func tracksFetchRequest() -> NSFetchRequest<Track> {
        let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Track.index, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "enabled == YES")
        fetchRequest.fetchLimit = 8
        return fetchRequest
    }
    
    private func getTracks(for groupItem: GroupItem?, context moc: NSManagedObjectContext) -> [Track]? {
        guard let groupItem = groupItem,
              let group = object(for: groupItem, context: moc) as? TrackGroup else { return nil }
        return getTracks(for: group, context: moc)
    }
    
    private func getTracks(for group: TrackGroup, context moc: NSManagedObjectContext) -> [Track]? {
        let fetchRequest = tracksFetchRequest()
        let groupsPredicate = NSPredicate(format: "%@ in groups", group)
        let predicates = [fetchRequest.predicate, groupsPredicate].compactMap { $0 }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return (try? moc.fetch(fetchRequest))
    }
}

//MARK: - TracksEntry

struct TracksEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let trackController: TrackController
    let tracks: [Track]
    
    internal init(date: Date, configuration: ConfigurationIntent, controller: TrackController = TrackController(observeChanges: false), tracks: [Track] = []) {
        self.date = date
        self.configuration = configuration
        self.trackController = controller
        self.tracks = tracks
    }
}

//MARK: - TicksWidgetEntryView

struct TicksWidgetEntryView : View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var widgetFamily
    
    //MARK: Properties
    
    var entry: Provider.Entry
    
    var bonusDays: Int {
        (!(entry.configuration.showTrackIcons?.boolValue ?? true)).int
    }
    
    var defaultNumDays: Int {
        switch widgetFamily {
        case .systemSmall:
            return 5 + bonusDays
        case .systemMedium:
            return 4 + bonusDays
        default:
            return 7 + bonusDays
        }
    }
    
    var maxNumDays: Int {
        switch widgetFamily {
        case .systemSmall, .systemMedium:
            return 6 + bonusDays
        default:
            return 9 + bonusDays
        }
    }
    
    var numDays: Int {
        entry.configuration.daysMode == .automatic
            ? defaultNumDays
            : min(entry.configuration.numDays?.intValue ?? defaultNumDays, maxNumDays)
    }
    
    var defaultNumTracks: Int {
        switch widgetFamily {
        case .systemSmall:
            return 4
        case .systemMedium:
            return 6
        default:
            return 5
        }
    }
    
    var maxNumTracks: Int {
        switch widgetFamily {
        case .systemSmall:
            return 6
        default:
            return 8
        }
    }
    
    var numTracks: Int {
        switch entry.configuration.tracksMode {
        case .automatic,
             // If .choose or .group are selected but the user doesn't make
             // a choice, it falls back to the default fetch request.
             .choose where entry.configuration.tracks?.isEmpty ?? true,
             .group where entry.configuration.group == nil:
            return defaultNumTracks
        default:
            return maxNumTracks
        }
    }
    
    var tracks: Array<Track>.SubSequence {
        entry.tracks.prefix(numTracks)
    }
    
    var compact: Bool {
        [.systemSmall, .systemMedium].contains(widgetFamily)
    }
    
    //MARK: Body

    var body: some View {
        VStack(spacing: 4) {
//            Text(entry.date, formatter: dateFormatter)
            if entry.configuration.showTrackIcons?.boolValue ?? true {
                HStack(spacing: 4) {
                    Rectangle()
                        .opacity(0)
                        .frame(width: compact ? 30 : 50)
                    ForEach(tracks) { track in
                        RoundedRectangle(cornerRadius: 3)
                            .foregroundColor(Color(.systemFill))
                            .overlay(Group {
                                if let systemImage = track.systemImage {
                                    Image(systemName: systemImage)
                                        .font(compact ? .system(size: 11) : .body)
                                }
                            })
                    }
                }
                .frame(maxHeight: 30)
                
                Divider()
            }
            
            ForEach(0..<numDays) { dayComplement in
                let day = numDays - 1 - dayComplement
                DayRow(day, tracks: tracks, spaces: false, lines: false, widget: true, compact: compact)
                
                if dayComplement < numDays - 1 {
                    if entry.configuration.weekSeparators?.boolValue ?? true
                        && entry.trackController.weekend(day: day) {
                        Capsule()
                            .foregroundColor(.gray)
                            .frame(height: 2)
                            .padding(.vertical, compact ? 0 : 2)
                    } else if !compact {
                        Divider()
                    }
                }
            }
        }
        .padding(12)
        .background(colorScheme == .dark ? Color(.systemGroupedBackground) : Color(.systemBackground))
    }
    
    // You can uncomment this and the above Text for easier debugging
    // so you can see when the widget refreshes.
    /*
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .long
        return dateFormatter
    }()
    */
}

//MARK: - TicksWidget

@main
struct TicksWidget: Widget {
    @Environment(\.colorScheme) private var colorScheme
    let kind: String = "TicksWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            // I feel like there should be a more elegant way to add manual appearance
            // control that doesn't involve two extra layers of indentation.
            Group {
                if [.light, .dark].contains(entry.configuration.appearance) {
                    TicksWidgetEntryView(entry: entry)
                        .environmentObject(entry.trackController)
                        .environment(\.colorScheme, entry.configuration.appearance == .light ? .light : .dark)
                } else {
                    TicksWidgetEntryView(entry: entry)
                        .environmentObject(entry.trackController)
                }
            }
        }
        .configurationDisplayName("Tickmate")
        .description("Display the past few days of your favorite tracks.")
    }
}

//MARK: - Previews

struct TicksWidget_Previews: PreviewProvider {
    static let trackController = TrackController(observeChanges: false, preview: true)
    
    static var previews: some View {
        ticksWidget(tracksCount: 3, days: 2, family: .systemSmall)
        ticksWidget(tracksCount: 4, days: 5, family: .systemSmall)
            .environment(\.colorScheme, .dark)
        ticksWidget(tracksCount: 5, days: 4, family: .systemMedium)
        ticksWidget(tracksCount: 4, days: 7, family: .systemLarge)
        ticksWidget(tracksCount: 5, days: 10, family: .systemLarge)
    }
    
    static func tracks(_ count: Int) -> [Track] {
        Array(trackController.fetchedResultsController.fetchedObjects!.prefix(count))
    }
    
    static func ticksWidget(tracksCount: Int, days: Int, family: WidgetFamily) -> some View {
        TicksWidgetEntryView(entry: TracksEntry(date: Date(), configuration: config(days: days), controller: trackController, tracks: tracks(tracksCount)))
            .environmentObject(trackController)
            .previewContext(WidgetPreviewContext(family: family))
    }
    
    static func config(days: Int) -> ConfigurationIntent {
        let config = ConfigurationIntent()
        config.numDays = NSNumber(integerLiteral: days)
        return config
    }
}
