//
//  GroupRepresentation.swift
//  Tickmate
//
//  Created by Isaac Lyons on 5/14/21.
//

import Foundation

struct GroupRepresentation: Equatable, Hashable {
    var name: String
    var tracks: Set<Track>
    
    var loaded = false
    
    init(name: String = "", tracks: Set<Track> = []) {
        self.name = name
        self.tracks = tracks
    }
    
    mutating func load(_ group: TrackGroup) {
        guard !loaded else { return }
        name = group.name == "New Group" ? "" : group.name ?? ""
        tracks = group.tracks as? Set<Track> ?? []
        loaded = true
    }
    
    func save(to group: TrackGroup) {
        guard self != group else { return }
        group.name = name
        group.tracks = tracks as NSSet
    }
    
    static func == (rep: GroupRepresentation, group: TrackGroup) -> Bool {
        return
            rep.name == group.name &&
            group.tracks == nil ? (rep.tracks.isEmpty) : (rep.tracks == group.tracks as? Set<Track>)
    }
    
    static func == (group: TrackGroup, rep: GroupRepresentation) -> Bool {
        return rep == group
    }
    
    static func != (rep: GroupRepresentation, group: TrackGroup) -> Bool {
        return !(rep == group)
    }
    
    static func != (group: TrackGroup, rep: GroupRepresentation) -> Bool {
        return !(rep == group)
    }
}
