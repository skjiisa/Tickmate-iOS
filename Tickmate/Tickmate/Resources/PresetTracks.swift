//
//  PresetTracks.swift
//  Tickmate
//
//  Created by Isaac Lyons on 3/9/21.
//

import Foundation

let PresetTracks: [TrackRepresentation] = [
    // Colors based on light-mode versions of Apple adaptable system colors.
    // https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/color/
    // The adaptable colors con't be used, though, as they can't be extracted into their RGB values.
    TrackRepresentation(name: "Read", red: 255, green: 204, blue: 0, multiple: false, reversed: false, systemImage: "book.closed"),
    TrackRepresentation(name: "Exercised", red: 0, green: 122, blue: 255, multiple: false, reversed: false, systemImage: "figure.walk"),
    TrackRepresentation(name: "Didn't eat junk food", red: 255, green: 45, blue: 85, multiple: false, reversed: true, systemImage: "trash"),
    TrackRepresentation(name: "Walked pet", red: 52, green: 199, blue: 89, multiple: false, reversed: false, systemImage: "hare.fill"),
    TrackRepresentation(name: "Took medication", red: 90, green: 200, blue: 250, multiple: false, reversed: false, systemImage: "pills.fill"),
    TrackRepresentation(name: "Practiced instrument", red: 88, green: 86, blue: 214, multiple: false, reversed: false, systemImage: "pianokeys"),
    TrackRepresentation(name: "Didn't smoke", red: 255, green: 149, blue: 0, multiple: false, reversed: true, systemImage: "flame"),
    TrackRepresentation(name: "Symptom occurred", red: 255, green: 59, blue: 48, multiple: true, reversed: false, systemImage: "waveform.path.ecg")
]
