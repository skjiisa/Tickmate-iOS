//
//  Animation+Push.swift
//  Tickmate
//
//  Created by Isaac Lyons on 5/19/21.
//

import SwiftUI

extension Animation {
    // Derived by screen recording a standard NavigationLink and going frame-
    // by-frame, counting the distance traveled from the edge of the screen.
    // This was then plotted and a Bezier curve roughly matched onto it by-hand.
    // The coordinates of the control points are the values in the timingCurve.
    static var push: Animation {
        .timingCurve(187/677.5, 1 - 30.5/485.5, 193/677.5, 1 - -3.5/485.5, duration: 0.5)
    }
}
