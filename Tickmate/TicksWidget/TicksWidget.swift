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
        let entry = TracksEntry(date: Date(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [TracksEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        /*
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }
        */
        
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Track.index, ascending: true)]
        fetchRequest.fetchLimit = 4
        
        let tracks = try? context.fetch(fetchRequest)
        
        entries.append(Entry(date: Date(), configuration: configuration, tracks: tracks ?? []))

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct TracksEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let tracks: [Track]
    
    internal init(date: Date, configuration: ConfigurationIntent, tracks: [Track] = []) {
        self.date = date
        self.configuration = configuration
        self.tracks = tracks
    }
}

struct TicksWidgetEntryView : View {
    var entry: Provider.Entry
    let numDays = 5

    var body: some View {
        VStack(spacing: 4) {
            Text(entry.date, style: .date)
            ForEach(0..<numDays) { dayComplement in
                DayRow(numDays - 1 - dayComplement, tracks: entry.tracks, spaces: false, lines: false, compact: true)
            }
        }
        .padding()
    }
}

@main
struct TicksWidget: Widget {
    let kind: String = "TicksWidget"
    let trackController = TrackController(observeChanges: false)

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            TicksWidgetEntryView(entry: entry)
                .environmentObject(trackController)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        
    }
}

struct TicksWidget_Previews: PreviewProvider {
    static let trackController = TrackController(observeChanges: false, preview: true)
    
    static var previews: some View {
        TicksWidgetEntryView(entry: TracksEntry(date: Date(), configuration: ConfigurationIntent(), tracks: Array(trackController.fetchedResultsController.fetchedObjects!.prefix(4))))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .environmentObject(trackController)
    }
}
