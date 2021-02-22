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
    
    func ticks(for track: Track, on day: Int) -> Set<Tick> {
        let tickController = tickControllers[track] ?? {
            let tickController = TickController(track: track)
            tickControllers[track] = tickController
            return tickController
        }()
        
        return tickController.ticks(on: day)
    }
    
}
