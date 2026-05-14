//
//  BackupArchive.swift
//  Tickmate
//
//  Created by Elaine Lyons on 5/12/26.
//

import Foundation
import UniformTypeIdentifiers

extension UTType {
    static let tickmateBackup = UTType(exportedAs: "app.lyons.Tickmate.backup")
}

struct BackupArchive: Codable {
    static let currentFormatVersion = 1

    var format: String = "tickmate-backup"
    var formatVersion: Int = Self.currentFormatVersion
    var appVersion: String?
    var appBuild: String?
    var exportDate: Date?
    var settings: BackupSettings?
    var groups: [BackupGroup]?
    var tracks: [BackupTrack]?
}

struct BackupSettings: Codable {
    var customDayStart: Bool?
    var customDayStartMinutes: Int?
    var weekStartDay: Int?
    var weekSeparatorSpaces: Bool?
    var weekSeparatorLines: Bool?
    var relativeDates: Bool?
    var showAllTracks: Bool?
    var showUngroupedTracks: Bool?
    var todayAtTop: Bool?
    var todayLock: Bool?
}

struct BackupGroup: Codable {
    var id: String?
    var index: Int16?
    var name: String?
}

struct BackupTrack: Codable {
    var id: String?
    var name: String?
    var color: Int32?
    var enabled: Bool?
    var index: Int16?
    var isArchived: Bool?
    var multiple: Bool?
    var reversed: Bool?
    var startDate: String?
    var systemImage: String?
    var groupIDs: [String]?
    var ticks: [BackupTick]?
}

struct BackupTick: Codable {
    var dayOffset: Int16?
    var count: Int16?
    var duplicate: Bool?
    var modified: Date?
}
