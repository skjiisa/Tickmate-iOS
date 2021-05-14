//
//  Tickmate+Wrapping.swift
//  Tickmate
//
//  Created by Isaac Lyons on 5/14/21.
//

import Foundation

extension TrackGroup {
    var editorName: String {
        get { name == "New Group" ? "" : name ?? "" }
        set { name = newValue }
    }
}
