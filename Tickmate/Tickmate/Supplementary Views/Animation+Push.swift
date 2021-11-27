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
    // I then realized the values I computed were actually just approximations
    // for 1/4 and 1, as is reflected here.
    static var push: Animation {
        .timingCurve(0.25, 1, 0.25, 1, duration: 0.5)
    }
}
