//
//  View+Conditional.swift
//  Tickmate
//
//  Created by Isaac Lyons on 9/29/21.
//

import SwiftUI

extension View {
    // From https://www.avanderlee.com/swiftui/conditional-view-modifier/
    /// Applies the given transform if the given condition evaluates to `true`.
    ///
    /// Note that if `condition` changes, the view will entirely reload, not just have the modifiers change value.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, @ViewBuilder transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

extension Bool {
    static var iOS14: Bool {
        guard #available(iOS 15, *) else { return true }
        return false
    }
}
