//
//  Defaults.swift
//  Tickmate
//
//  Created by Isaac Lyons on 3/9/21.
//

import Foundation

let groupID = "group.vc.isv.Tickmate"

enum Defaults: String {
    case customDayStart             // Bool
    case customDayStartMinutes      // Int
    case weekSeparatorSpaces        // Bool
    case weekSeparatorLines         // Bool
    case weekStartDay               // Int
    case relativeDates              // Bool
    case onboardingComplete         // Bool
    case showAllTracks              // Bool
    case showUngroupedTracks        // Bool
    case groupPage                  // Int
    case appGroupDatabaseMigration  // Bool
    case userDefaultsMigration      // Bool
    case lastUpdateTime             // String
}
