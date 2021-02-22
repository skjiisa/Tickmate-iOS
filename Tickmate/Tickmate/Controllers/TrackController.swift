//
//  TrackController.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/21/21.
//

import Foundation

class TrackController: ObservableObject {
    
    private var tickControllers: [Track: TickController] = [:]
    
    func loadTicks(for track: Track) {
        if let tickController = tickControllers[track] {
            tickController.loadTicks()
        } else {
            tickControllers[track] = TickController(track: track)
        }
    }
    
}
