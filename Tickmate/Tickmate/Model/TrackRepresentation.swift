//
//  TrackRepresentation.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/23/21.
//

import SwiftUI
import SFSafeSymbols

class TrackRepresentation: ObservableObject {
    var name: String
    var color: Color
    var multiple: Bool
    var reversed: Bool
    var systemImage: SFSymbol?
    
    init() {
        name = ""
        color = Color(hue: Double.random(in: 0...1), saturation: 1, brightness: 1)
        multiple = false
        reversed = false
    }
    
    func load(track: Track) {
        name = track.name ?? ""
        multiple = track.multiple
        reversed = track.reversed
        if let trackImage = track.systemImage {
            systemImage = SFSymbol(rawValue: trackImage)
        } else {
            systemImage = SFSymbol.allCases.randomElement()
        }
    }
    
    func save(to track: Track) {
        // Avoid writing duplicate information as doing
        // so will mark the context as modified even
        // though it wouldn't be.
        if track.name != name {
            track.name = name
        }
        if track.multiple != multiple {
            track.multiple = multiple
        }
        if track.reversed != reversed {
            track.reversed = reversed
        }
        if track.systemImage != systemImage?.rawValue {
            track.systemImage = systemImage?.rawValue
        }
        
    }
}
