//
//  Tickmate+Convenience.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/21/21.
//

import CoreData
import SwiftUI

extension TrackGroup {
    @discardableResult
    convenience init(name: String, context moc: NSManagedObjectContext) {
        self.init(context: moc)
        self.name = name
    }
}

extension Track {
    @discardableResult
    convenience init(name: String, color: Int32? = nil, multiple: Bool = false, reversed: Bool = false, startDate: String, systemImage: String? = nil, index: Int16, context moc: NSManagedObjectContext) {
        self.init(context: moc)
        self.name = name
        self.color = color ?? Int32(Color(hue: Double.random(in: 0...1), saturation: 1, brightness: 1).rgb)
        self.multiple = multiple
        self.reversed = reversed
        self.startDate = startDate
        self.systemImage = systemImage ?? SymbolsList.randomElement()
        self.index = index
    }
    
    var lightText: Bool {
        let r = Double((color & 0xff0000) >> 16)
        let g = Double((color & 0x00ff00) >> 8)
        let b = Double((color & 0x0000ff))
        let luma = (0.299 * r + 0.587 * g + 0.114 * b) / 255
        return luma < 2/3
    }
}

extension Tick {
    @discardableResult
    convenience init(track: Track, dayOffset: Int16, context moc: NSManagedObjectContext) {
        self.init(context: moc)
        self.track = track
        self.dayOffset = dayOffset
        self.count = 1
        self.modified = Date()
    }
    
    @discardableResult
    convenience init?(track: Track, dayOffset: Int16) {
        guard let moc = track.managedObjectContext else { return nil }
        self.init(track: track, dayOffset: dayOffset, context: moc)
    }
}

extension NSMutableSet {
    func toggle(_ member: Element) {
        if contains(member) {
            remove(member)
        } else {
            add(member)
        }
    }
}

extension Set {
    mutating func toggle(_ member: Element) {
        if contains(member) {
            remove(member)
        } else {
            insert(member)
        }
    }
}
