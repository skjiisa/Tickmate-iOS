//
//  PagingView.swift
//  Tickmate
//
//  Created by Elaine Lyons on 11/18/21.
//

import SwiftUI

struct PagingView: View {
    /*
    @EnvironmentObject private var trackController: TrackController
    
    @FetchRequest(
        entity: Track.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Track.index, ascending: true)],
        predicate: NSPredicate(format: "enabled == YES"),
        animation: .default)
    private var tracks: FetchedResults<Track>
    */
    @FetchRequest(
        entity: TrackGroup.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TrackGroup.index, ascending: true)],
        predicate: NSPredicate(format: "tracks.@count > 0"))
    private var groups: FetchedResults<TrackGroup>
    
    @ObservedObject var pagingController: PagingController
    
    private let days = 133
    
    private var bar: some View {
        HStack(spacing: 0) {
            LazyVStack {
                ForEach(0..<days) { i in
                    Text("\(i)")
                        .padding(4)
                        .frame(height: 32)
                }
            }
            .frame(width: 80)
            .background(Color(.systemBackground)
                            .shadow(radius: pagingController.moving ? 8 : 0))
            // Would need to get an anchor point in the center of the screen to have a scale effect
            //.scaleEffect(pagingController.moving ? 1.05 : 1)
            Divider()
            Spacer()
        }
        .clipped()
    }
    
    var body: some View {
        GeometryReader { geo in
            // This is the main vertical ScrollView whose scroll bar stays on the right of the screen
            ScrollView(.vertical, showsIndicators: true) {
                // This is the tab view, using scrollView.isPagingEnabled = true in PagingController
                ScrollView(.horizontal, showsIndicators: false) {
                    // Non-lazy HStack so that the width can be calculated even when device is rotated.
                    // If it was lazy, the columns off-screen wouldn't be updated and would still have
                    // the same width as before the rotation, so the pages would get offset.
                    // Update: turns out the lazy loading algorithms are actually more intensive than
                    // just rendering everything lmao, at least with as many Tracks as I tried.
                    HStack(spacing: 0) {
                        /*
                        ForEach(tracks) { track in
                            // This LazyHStack doesn't actually stack anything. It exists entirely
                            // for its laziness. It sets its width whenever the screen width
                            // changes while the content inside it is loaded lazily.
                            LazyHStack(spacing: 0) {
                                Column(tickController: trackController.tickController(for: track))
                                    .padding(.leading, 88)
                                    .padding(.trailing)
                                    .frame(width: geo.size.width)
                            }
                            .frame(width: geo.size.width)
                        }
                        */
                        //TODO: Add All and Ungrouped
                        ForEach(groups) { group in
                            TracksPage(group: group, days: days)
                                .padding(.leading, 88)
                                .padding(.trailing)
                                .frame(width: geo.size.width)
                        }
                    }
                }
                .introspectScrollView { scrollView in
                    pagingController.load(scrollView: scrollView)
                }
                .frame(width: geo.size.width, alignment: .leading)
                .overlay(bar)
            }
        }
    }
}

struct PagingView_Previews: PreviewProvider {
    static var previews: some View {
        PagingView(pagingController: PagingController())
    }
}
