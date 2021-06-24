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
        
        let name = (try? context.fetch(fetchRequest).compactMap { $0.name }.joined(separator: ", ")) ??? "Timeline"
        
        entries.append(Entry(date: Date(), configuration: configuration, test: name))

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let test: String
}

struct TicksWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text(entry.date, style: .time)
            Text(entry.test)
        }
    }
}

@main
struct TicksWidget: Widget {
    let kind: String = "TicksWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            TicksWidgetEntryView(entry: entry)
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
