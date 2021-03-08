//
//  TrackController.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/21/21.
//

import CoreData
import SwiftDate

class TrackController: ObservableObject {
    
    var tickControllers: [Track: TickController] = [:]
    let date = Date()
    
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
    
    /*
    func ticks(on day: Int, for track: Track) -> [Tick] {
        tickController(for: track).ticks(on: day)
    }
    
    func tick(day: Int, for track: Track) {
        objectWillChange.send()
        tickController(for: track).tick(day: day)
    }
     */
    
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
