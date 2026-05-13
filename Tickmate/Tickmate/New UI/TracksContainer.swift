//
//  TracksContainer.swift
//  Tickmate
//
//  Created by Elaine Lyons on 1/8/23.
//

import Foundation

class TracksContainer: ObservableObject {
    @Published var tracks: [Track] = []
}
