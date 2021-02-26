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
    
    var lightText: Bool {
        let r = Double((color & 0xff0000) >> 16)
        let g = Double((color & 0x00ff00) >> 8)
        let b = Double((color & 0x0000ff))
        let luma = (0.299 * r + 0.587 * g + 0.114 * b) / 255
        return luma < 0.5
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
