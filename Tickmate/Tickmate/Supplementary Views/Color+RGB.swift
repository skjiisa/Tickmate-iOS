//
//  Color+RGB.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/23/21.
//

import SwiftUI

extension Color {
    /// Returns the color (excluding alpha) as an RGB color.
    var rgb: Int {
        guard let components = cgColor?.components,
              components.count >= 3 else {
            return 0
        }
        
        let r = Int(round(components[0] * 255))
        let g = Int(round(components[1] * 255))
        let b = Int(round(components[2] * 255))
        return r << 16 + g << 8 + b
    }
    
    /// Initialize based on a 24-bit integer RGB value, such as from a hex code. Does not support alpha channel.
    /// - Parameter rgb: An integer RGB value without alpha.
    init(rgb: Int) {
        let r = Double((rgb & 0xff0000) >> 16) / 255
        let g = Double((rgb & 0x00ff00) >> 8) / 255
        let b = Double((rgb & 0x0000ff)) / 255
        self.init(red: r, green: g, blue: b)
    }
}

extension UIColor {
    /// Initialize based on a 24-bit integer RGB value, such as from a hex code. Does not support alpha channel.
    /// - Parameter rgb: An integer RGB value without alpha.
    convenience init(rgb: Int) {
        let r = Double((rgb & 0xff0000) >> 16) / 255
        let g = Double((rgb & 0x00ff00) >> 8) / 255
        let b = Double((rgb & 0x0000ff)) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
