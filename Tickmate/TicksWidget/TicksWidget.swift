//
//  TicksWidget.swift
//  TicksWidget
//
//  Created by Isaac Lyons on 6/23/21.
//

import WidgetKit
import SwiftUI
import Intents
import CoreData

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
        entries.append(Entry(date: Calendar.current.date(byAdding: .minute, value: 30, to: Date())!, configuration: configuration, controller: trackController, tracks: tracks))

        let timeline = Timeline(entries: entries, policy: .atEnd)
        
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
    
    private func tracks(for configuration: ConfigurationIntent, context moc: NSManagedObjectContext) -> [Track]? {
        (configuration.tracksMode != .choose ? nil : configuration.tracks?.prefix(8).compactMap { trackItem in
            guard let idString = trackItem.identifier,
                  let url = URL(string: idString),
                  let id =
                    moc.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url)  else { return nil }
            return moc.object(with: id) as? Track
        }) ??? {
            let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Track.index, ascending: true)]
            fetchRequest.fetchLimit = 8
            
            return (try? moc.fetch(fetchRequest))
        }()
    }
}

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

struct TicksWidgetEntryView : View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var widgetFamily
    
    var entry: Provider.Entry
    
    var defaultNumDays: Int {
        switch widgetFamily {
        case .systemSmall:
            return 5
        case .systemMedium:
            return 4
        default:
            return 7
        }
    }
    
    var maxNumDays: Int {
        let num: Int
        switch widgetFamily {
        case .systemSmall, .systemMedium:
            num = 6
        default:
            num = 9
        }
        let bonus = !(entry.configuration.showTrackIcons?.boolValue ?? true)
        return num + bonus.int
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
        entry.configuration.tracksMode == .automatic
            ? defaultNumTracks
            : maxNumTracks
    }
    
    var tracks: Array<Track>.SubSequence {
        entry.tracks.prefix(numTracks)
    }
    
    var compact: Bool {
        [.systemSmall, .systemMedium].contains(widgetFamily)
    }

    var body: some View {
        VStack(spacing: 4) {
//            Text(entry.date, formatter: dateFormatter)
            if entry.configuration.showTrackIcons?.boolValue ?? true {
                HStack(spacing: 4) {
                    Rectangle()
                        .opacity(0)
                        .frame(width: compact ? 30 : 80)
                    ForEach(tracks) { track in
                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .foregroundColor(Color(.systemFill))
                            if let systemImage = track.systemImage {
                                Image(systemName: systemImage)
                                    .font(compact ? .system(size: 11) : .body)
                            }
                        }
                    }
                }
                
                Divider()
            }
            
            ForEach(0..<numDays) { dayComplement in
                DayRow(numDays - 1 - dayComplement, tracks: tracks, spaces: false, lines: false, widget: true, compact: compact)
                if !compact {
                    Divider()
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

@main
struct TicksWidget: Widget {
    let kind: String = "TicksWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            TicksWidgetEntryView(entry: entry)
                .environmentObject(entry.trackController)
        }
        .configurationDisplayName("Tickmate")
        .description("Display the past few days of your favorite tracks.")
    }
}

struct TicksWidget_Previews: PreviewProvider {
    static let trackController = TrackController(observeChanges: false, preview: true)
    
    static var previews: some View {
        ticksWidget(tracksCount: 3, days: 4, family: .systemSmall)
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
