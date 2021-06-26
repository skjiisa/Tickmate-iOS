//
//  Tickmate+Wrapping.swift
//  Tickmate
//
//  Created by Isaac Lyons on 5/14/21.
//

import Foundation

extension TrackGroup {
    var wrappedName: String {
        get { name ?? "" }
        set { name = newValue }
    }
    
    var displayName: String {
        name ??? "New Group"
    }
}

extension Bool {
    var int: Int {
        self ? 1 : 0
    }
}

infix operator ???: NilCoalescingPrecedence

func ??? <C: Collection>(optional: C?, defaultValue: @autoclosure () throws -> C) rethrows -> C {
    if let value = optional,
       !value.isEmpty {
        return value
    }
    return try defaultValue()
}

func ??? <C: Collection>(optional: C?, defaultValue: @autoclosure () throws -> C?) rethrows -> C? {
    if let value = optional,
       !value.isEmpty {
        return value
    }
    return try defaultValue()
}
