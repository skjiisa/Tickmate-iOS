//
//  TrackGroups.swift
//  Tickmate
//
//  Created by Isaac Lyons on 5/31/21.
//

import Foundation

class TrackGroups: ObservableObject {
    @Published private(set) var set = Set<TrackGroup>()
    @Published private(set) var array = [TrackGroup]()
    
    var name: String {
        array.map { $0.displayName }.joined(separator: ", ")
    }
    
    func load(_ track: Track) {
        guard let groups = track.groups as? Set<TrackGroup> else { return }
        set = groups
        array = groups.sorted(by: { $0.index < $1.index })
    }
    
    func save(to track: Track) {
        track.groups = set as NSSet
    }
    
    func toggle(_ group: TrackGroup, in track: Track) {
        if set.contains(group) {
            set.remove(group)
            array.removeAll(where: { $0 == group })
        } else {
            set.insert(group)
            array.insert(group, at: array.firstIndex(where: { $0.index > group.index }) ?? array.count)
        }
    }
    
    func contains(_ group: TrackGroup) -> Bool {
        set.contains(group)
    }
}
