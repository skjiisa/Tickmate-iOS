//
//  TrackRepresentation.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/23/21.
//

import SwiftUI

struct TrackRepresentation: Equatable, Hashable {
    var name: String
    var color: Color
    var multiple: Bool
    var reversed: Bool
    var systemImage: String?
    
    init(name: String = "", color: Color = .black, multiple: Bool = false, reversed: Bool = false, systemImage: String? = nil) {
        self.name = name
        self.color = color
        self.multiple = multiple
        self.reversed = reversed
        self.systemImage = systemImage
    }
    
    var lightText: Bool {
        guard let components = color.cgColor?.components,
              components.count >= 3 else { return true }
        
        let r = components[0]
        let g = components[1]
        let b = components[2]
        let luma = (0.299 * r + 0.587 * g + 0.114 * b)
        return luma < 0.5
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
