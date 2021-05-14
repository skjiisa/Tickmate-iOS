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

infix operator ???: NilCoalescingPrecedence
extension Collection {
    static func ??? (lhs: Self?, rhs: Self) -> Self {
        if let lhs = lhs,
           !lhs.isEmpty {
            return lhs
        }
        return rhs
    }
}
