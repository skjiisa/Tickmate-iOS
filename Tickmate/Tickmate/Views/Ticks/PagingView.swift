//
//  PagingView.swift
//  Tickmate
//
//  Created by Elaine Lyons on 11/18/21.
//

import SwiftUI

struct PagingView<C: RandomAccessCollection>: View where C.Element == TrackGroup {
    
    var groups: C
    
    @EnvironmentObject var pagingController: PagingController
    
    private let days = 133
    
    private var bar: some View {
        HStack(spacing: 0) {
            LazyVStack {
                // Spacer views for the sake of the shadow
                ForEach(0..<4) { _ in
                    Color.clear
                        .padding(4)
                        .frame(height: 32)
                }
                
                ForEach(0..<days) { i in
                    Text("\(i)")
                        .padding(4)
                        .frame(height: 32)
                }
                
                ForEach(0..<4) { _ in
                    Color.clear
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
                    // Non-lazy HStack as the lazy loading algorithms are actually more intensive than
                    // just rendering everything, at least with as many Tracks as I tried. Lazy loading
                    // also causes issues with device rotation as it doesn't recalculated the width of
                    // the pages off-screen.
                    HStack(spacing: 0) {
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
                .padding(.top, 4)
            }
        }
    }
}

struct PagingView_Previews: PreviewProvider {
    static var previews: some View {
        PagingView(groups: [PersistenceController.preview.previewGroup!])
            .environmentObject(PagingController())
    }
}
