//
//  TrackRepresentation.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/23/21.
//

import SwiftUI

struct TrackRepresentation: Equatable {
    var name: String
    var color: Color
    var multiple: Bool
    var reversed: Bool
    var systemImage: String?
    
    init() {
        name = ""
        color = .black
        multiple = false
        reversed = false
    }
    
    mutating func load(track: Track) {
        name = track.name == "New Track" ? "" : track.name ?? ""
        multiple = track.multiple
        reversed = track.reversed
        
        if let trackImage = track.systemImage {
            systemImage = trackImage
        } else {
            systemImage = SymbolsList.randomElement()
        }
        
        color = Color(rgb: Int(track.color))
    }
    
    func save(to track: Track) {
        // Avoid writing duplicate information as doing
        // so will mark the context as modified even
        // though it wouldn't be.
        guard self != track else { return }
        track.name = name
        track.multiple = multiple
        track.reversed = reversed
        track.systemImage = systemImage
        track.color = Int32(color.rgb)
    }
    
    static func == (rep: TrackRepresentation, track: Track) -> Bool {
        return
            rep.name == track.name &&
            rep.multiple == track.multiple &&
            rep.reversed == track.reversed &&
            rep.systemImage == track.systemImage &&
            Int32(rep.color.rgb) == track.color
    }
    
    static func == (track: Track, rep: TrackRepresentation) -> Bool {
        return rep == track
    }
    
    static func != (rep: TrackRepresentation, track: Track) -> Bool {
        return !(rep == track)
    }
    
    static func != (track: Track, rep: TrackRepresentation) -> Bool {
        return !(rep == track)
    }
}
