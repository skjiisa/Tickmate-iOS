//
//  TrackController.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/21/21.
//

import Foundation
import SwiftDate

class TrackController: ObservableObject {
    
    @Published var tickControllers: [Track: TickController] = [:]
    var date = Date()
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    private var weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
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
            weekday = weekdayFormatter.string(from: date)
        }
        
        return TextWithCaption(text: weekday, caption: dateFormatter.string(from: date))
    }
    
}
