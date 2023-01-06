//
//  UIHostingController+Closure.swift
//  Tickmate
//
//  Created by Elaine Lyons on 1/5/23.
//

import SwiftUI

extension UIHostingController {
    convenience init(root: () -> Content) {
        self.init(rootView: root())
    }
}
