//
//  TracksView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/19/21.
//

import SwiftUI

struct TracksView: View {
    @FetchRequest(
        entity: Track.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Track.name, ascending: true)])
    private var tracks: FetchedResults<Track>
    
    var body: some View {
        HStack {
            ForEach(tracks) { (track: Track) in
                if let systemImage = track.systemImage {
                    Image(systemName: systemImage)
                } else {
                    Text(track.name ?? "nil")
                }
            }
        }
    }
}

struct TracksView_Previews: PreviewProvider {
    static var previews: some View {
        TracksView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
