//
//  Defaults+Convenience.swift
//  Tickmate
//
//  Created by Elaine Lyons on 4/12/25.
//

import Foundation

extension UserDefaults {
    static let appGroup = UserDefaults(suiteName: groupID)
    
    /// Whether or not to show a group of all tracks.
    /// Use `UserDefaults.standard`.
    @objc var showAllTracks: Bool {
        get {
            bool(forKey: Defaults.showAllTracks.rawValue)
        }
        set {
            set(newValue, forKey: Defaults.showAllTracks.rawValue)
        }
    }
    
    /// Whether or not to show a group of all ungrouped tracks.
    /// Use `UserDefaults.standard`.
    @objc var showUngroupedTracks: Bool {
        get {
            bool(forKey: Defaults.showUngroupedTracks.rawValue)
        }
        set {
            set(newValue, forKey: Defaults.showUngroupedTracks.rawValue)
        }
    }
    
    @objc var groupsUnlocked: Bool {
        get {
            bool(forKey: StoreController.Products.groups.rawValue)
        }
        set {
            set(newValue, forKey: StoreController.Products.groups.rawValue)
        }
    }
}
