//
//  Tickmate+Convenience.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/21/21.
//

import CoreData

extension Track {
    convenience init(name: String, color: Int16, multiple: Bool = false, reversed: Bool = false, systemImage: String, context moc: NSManagedObjectContext) {
        self.init(context: moc)
        self.name = name
        self.color = color
        self.multiple = multiple
        self.reversed = reversed
        self.systemImage = systemImage
    }
}

extension Tick {
    convenience init(track: Track, context moc: NSManagedObjectContext) {
        self.init(context: moc)
        self.track = track
        self.timestamp = Date()
    }
}
