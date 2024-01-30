//
//  Animation+Push.swift
//  Tickmate
//
//  Created by Elaine Lyons on 5/19/21.
//

import SwiftUI

extension Animation {
    // Derived by screen recording a standard NavigationLink and going frame-
    // by-frame, counting the distance traveled from the edge of the screen.
    // This was then plotted and a Bezier curve roughly matched onto it by-hand.
    // The coordinates of the control points are the values in the timingCurve.
    // Update: Turns out the numbers are simpler than I realized lol.
    /// An animation curve matching that of the iOS native navigation push.
    static var push: Animation {
        .timingCurve(0.25, 1, 0.25, 1, duration: 0.5)
    }
}
