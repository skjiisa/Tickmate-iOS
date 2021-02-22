//
//  TickController.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/21/21.
//

import Foundation

class TickController: ObservableObject {
    
    let track: Track
    
    init(track: Track) {
        self.track = track
    }
    
}
