//
//  ProxyViews.swift
//  Tickmate
//
//  Created by Elaine Lyons on 4/12/25.
//

import SwiftUI

//MARK: Tracks Header Proxy

//struct TracksHeaderProxy: View {
//    @ObservedObject var tracksContainer: TracksContainer
//    
//    var body: some View {
//        TracksHeader(tracks: tracksContainer.tracks)
//    }
//}

//MARK: Day Row Proxy

// I would like for this to be scoped inside of DayRow, but
// I couldn't figure out how to get generics working properly
struct DayRowProxy: View {
    
    @ObservedObject var tracksContainer: TracksContainer
    
    let day: Int
    var spaces: Bool
    var lines: Bool
    var showDate: Bool
    // TODO: Today lock
    
    var body: some View {
        DayRow(day, tracks: tracksContainer.tracks, spaces: spaces, lines: lines, canEdit: true)
    }
}
