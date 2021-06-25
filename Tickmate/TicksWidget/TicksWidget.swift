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
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent(), test: "Placeholder")
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration, test: "Snapshot")
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

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
        let name = tracks?.compactMap { $0.name }.joined(separator: ", ") ??? "Timeline"
        
        entries.append(Entry(date: Date(), configuration: configuration, test: name, tracks: tracks ?? []))

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let test: String
    let tracks: [Track]
    
    internal init(date: Date, configuration: ConfigurationIntent, test: String, tracks: [Track] = []) {
        self.date = date
        self.configuration = configuration
        self.test = test
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
    static var previews: some View {
        TicksWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), test: "Preview"))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
