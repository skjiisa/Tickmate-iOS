//
//  Defaults.swift
//  Tickmate
//
//  Created by Elaine Lyons on 3/9/21.
//

import Foundation

let groupID = "group.vc.isv.Tickmate"

enum Defaults: String {
    case customDayStart             // Bool     App Group
    case customDayStartMinutes      // Int      App Group
    case weekSeparatorSpaces        // Bool
    case weekSeparatorLines         // Bool
    case weekStartDay               // Int      App Group
    case relativeDates              // Bool
    case onboardingComplete         // Bool
    case showAllTracks              // Bool
    case showUngroupedTracks        // Bool
    case groupPage                  // Int
    case appGroupDatabaseMigration  // Bool
    case userDefaultsMigration      // Bool     App Group
    case lastUpdateTime             // String   App Group
}

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
