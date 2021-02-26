//
//  Tickmate+Convenience.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/21/21.
//

import CoreData

extension Track {
    @discardableResult
    convenience init(name: String, color: Int32, multiple: Bool = false, reversed: Bool = false, systemImage: String? = nil, context moc: NSManagedObjectContext) {
        self.init(context: moc)
        self.name = name
        self.color = color
        self.multiple = multiple
        self.reversed = reversed
        self.systemImage = systemImage
    }
}

extension Tick {
    @discardableResult
    convenience init(track: Track, dayOffset: Int16, context moc: NSManagedObjectContext) {
        self.init(context: moc)
        self.track = track
        self.timestamp = Date()
        self.dayOffset = dayOffset
    }
    
    @discardableResult
    convenience init?(track: Track, dayOffset: Int16) {
        guard let moc = track.managedObjectContext else { return nil }
        self.init(track: track, dayOffset: dayOffset, context: moc)
    }
}
