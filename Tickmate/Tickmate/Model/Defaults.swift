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
    case todayAtTop                 // Bool     App Group
    case todayLock                  // Bool     App Group
    case lastCloudKitSyncTime       // Double   App Group (timeIntervalSince1970)
}
