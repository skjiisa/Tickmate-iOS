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
        
        // Download updated data from CloudKit
        DispatchQueue.global(qos: .background).async {
            let dispatchGroup = DispatchGroup()
            
            tracks.forEach { track in
                dispatchGroup.enter()
                trackController.tickController(for: track).loadCKTicks(completion: dispatchGroup.leave)
            }
            
            _ = dispatchGroup.wait(timeout: .now() + 20)
            completion(timeline)
        }
    }
    
    func tracks(for configuration: ConfigurationIntent, context moc: NSManagedObjectContext) -> [Track]? {
        (configuration.tracksMode != .list ? nil : configuration.tracks?.compactMap { trackItem in
            guard let idString = trackItem.identifier,
                  let url = URL(string: idString),
                  let id =
                    moc.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url)  else { return nil }
            return moc.object(with: id) as? Track
        }) ??? {
            let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Track.index, ascending: true)]
            fetchRequest.fetchLimit = configuration.tracksCount?.intValue ?? 1
            
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
    var entry: Provider.Entry
    var numDays: Int {
        entry.configuration.numDays?.intValue ?? 5
    }

    var body: some View {
        VStack(spacing: 4) {
//            Text(entry.date, formatter: dateFormatter)
            if entry.configuration.showTrackIcons?.boolValue ?? true {
                HStack(spacing: 4) {
                    Rectangle()
                        .opacity(0)
                        .frame(width: 30)
                    ForEach(entry.tracks) { track in
                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .foregroundColor(Color(.systemFill))
                            if let systemImage = track.systemImage {
                                Image(systemName: systemImage)
                                    .font(.system(size: 8))
                            }
                        }
                    }
                }
                
                Divider()
            }
            
            ForEach(0..<numDays) { dayComplement in
                DayRow(numDays - 1 - dayComplement, tracks: entry.tracks, spaces: false, lines: false, compact: true)
            }
        }
        .padding(12)
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
        TicksWidgetEntryView(entry: TracksEntry(date: Date(), configuration: ConfigurationIntent(), controller: trackController, tracks: Array(trackController.fetchedResultsController.fetchedObjects!.prefix(4))))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .environmentObject(trackController)
    }
}
