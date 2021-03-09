//
//  PresetTracksView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 3/9/21.
//

import SwiftUI

struct PresetTracksView: View {
    
    var tracks: [TrackRepresentation] = []
    
    var body: some View {
        List {
            ForEach(tracks, id: \.self) { track in
                Button {
                    
                } label: {
                    TrackRepresentationCell(trackRepresentation: track)
                }
            }
        }
        .navigationTitle("Example Tracks")
    }
}

struct TrackRepresentationCell: View {
    
    var trackRepresentation: TrackRepresentation
    
    private var caption: String {
        [trackRepresentation.multiple ? "Multiple" : nil, trackRepresentation.reversed ? "Reversed" : nil].compactMap { $0 }.joined(separator: ", ")
    }
    
    var body: some View {
        HStack {
            if let systemImage = trackRepresentation.systemImage {
                Image(systemName: systemImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .padding()
                    .background(trackRepresentation.color.cornerRadius(8))
                    .foregroundColor(trackRepresentation.lightText ? .white : .black)
            }
            TextWithCaption(text: trackRepresentation.name, caption: caption)
        }
    }
}

struct PresetTracksView_Previews: PreviewProvider {
    
    static private let exampleTrack = TrackRepresentation(name: "Read", color: .orange, systemImage: "book.closed")
    
    static var previews: some View {
        NavigationView {
            PresetTracksView(tracks: [exampleTrack])
        }
    }
}
