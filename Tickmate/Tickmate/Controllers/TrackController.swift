//
//  TrackController.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/21/21.
//

import Foundation

class TrackController: ObservableObject {
    
    @Published var tickControllers: [Track: TickController] = [:]
    
    func loadTicks(for track: Track) {
        if let tickController = tickControllers[track] {
            tickController.loadTicks()
        } else {
            tickControllers[track] = TickController(track: track)
        }
    }
    
    func tickController(for track: Track) -> TickController {
        tickControllers[track] ?? {
            let tickController = TickController(track: track)
            tickControllers[track] = tickController
            return tickController
        }()
    }
    
    func ticks(on day: Int, for track: Track) -> [Tick] {
        tickController(for: track).ticks(on: day)
    }
    
    func tick(day: Int, for track: Track) {
        objectWillChange.send()
        tickController(for: track).tick(day: day)
    }
    
}
