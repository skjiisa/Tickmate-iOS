//
//  ScrollController.swift
//  PageView
//
//  Created by Elaine Lyons on 2/14/22.
//

import UIKit

class ScrollController {
    static var shared = ScrollController()
    @Published var contentOffset: CGPoint = .zero
    @Published var isPaging = false
    var initialized = false
}
