//
//  PresetTracks.swift
//  Tickmate
//
//  Created by Isaac Lyons on 3/9/21.
//

import Foundation

let PresetTracks: [TrackRepresentation] = [
    TrackRepresentation(name: "Read", color: .yellow, multiple: false, reversed: false, systemImage: "book.closed"),
    TrackRepresentation(name: "Exercised", color: .blue, multiple: false, reversed: false, systemImage: "figure.walk"),
    TrackRepresentation(name: "Didn't eat junk food", color: .orange, multiple: false, reversed: true, systemImage: "trash"),
    TrackRepresentation(name: "Walked pet", color: .green, multiple: false, reversed: false, systemImage: "hare.fill"),
    TrackRepresentation(name: "Took medication", color: .red, multiple: false, reversed: false, systemImage: "pills.fill"),
    TrackRepresentation(name: "Practiced instrument", color: .blue, multiple: false, reversed: false, systemImage: "pianokeys"),
    TrackRepresentation(name: "Didn't smoke", color: .orange, multiple: false, reversed: true, systemImage: "flame"),
    TrackRepresentation(name: "Symptom occurred", color: .red, multiple: true, reversed: false, systemImage: "waveform.path.ecg")
]
