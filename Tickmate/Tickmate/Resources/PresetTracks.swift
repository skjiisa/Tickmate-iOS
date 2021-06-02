//
//  PresetTracks.swift
//  Tickmate
//
//  Created by Isaac Lyons on 3/9/21.
//

import Foundation

typealias TracksList = [(title: String, tracks: [TrackRepresentation])]

let PresetTracks: TracksList = [
    ("Daily habits", [
        // Colors based on light-mode versions of Apple adaptable system colors.
        // https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/color/
        // The adaptable colors con't be used, though, as they can't be extracted into their RGB values.
        .init(name: "Read", red: 255, green: 204, blue: 0, multiple: false, reversed: false, systemImage: "book.closed"),
        .init(name: "Exercised", red: 0, green: 122, blue: 255, multiple: false, reversed: false, systemImage: "figure.walk"),
        .init(name: "Didn't eat junk food", red: 255, green: 45, blue: 85, multiple: false, reversed: true, systemImage: "trash"),
        .init(name: "Walked pet", red: 52, green: 199, blue: 89, multiple: false, reversed: false, systemImage: "hare.fill"),
        .init(name: "Took medication", red: 90, green: 200, blue: 250, multiple: false, reversed: false, systemImage: "pills.fill"),
        .init(name: "Practiced instrument", red: 88, green: 86, blue: 214, multiple: false, reversed: false, systemImage: "pianokeys"),
        .init(name: "Didn't smoke", red: 255, green: 149, blue: 0, multiple: false, reversed: true, systemImage: "flame"),
        .init(name: "Symptom occurred", red: 255, green: 59, blue: 48, multiple: true, reversed: false, systemImage: "waveform.path.ecg")
    ]),
    ("Occasional tasks", [
        .init(name: "Washed hair", red: 152, green: 109, blue: 50, multiple: false, reversed: false, systemImage: "cloud.heavyrain"),
        .init(name: "Changed sheets", red: 251, green: 246, blue: 219, multiple: false, reversed: false, systemImage: "bed.double"),
        .init(name: "Changed towels in bathroom", red: 177, green: 223, blue: 247, multiple: false, reversed: false, systemImage: "map")
    ])
]
