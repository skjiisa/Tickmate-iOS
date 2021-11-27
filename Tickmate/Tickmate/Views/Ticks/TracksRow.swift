//
//  TracksRow.swift
//  Tickmate
//
//  Created by Isaac Lyons on 11/20/21.
//

import SwiftUI

struct TracksRow: View {
    
    @EnvironmentObject var pagingController: PagingController
    
    private var fetchRequest: FetchRequest<Track>
    private var tracks: FetchedResults<Track> {
        fetchRequest.wrappedValue
    }
    
    @Binding var showingTrack: Track?
    
    init(showingTrack: Binding<Track?>) {
        _showingTrack = showingTrack
        fetchRequest = FetchRequest(
            entity: Track.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Track.index, ascending: true)],
            predicate: NSPredicate(format: "enabled == YES"))
    }
    
    init(group: TrackGroup, showingTrack: Binding<Track?>) {
        _showingTrack = showingTrack
        fetchRequest = FetchRequest(
            entity: Track.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Track.index, ascending: true)],
            predicate: NSPredicate(format: "enabled == YES AND %@ IN groups", group))
    }
    
    init(fetchRequest: FetchRequest<Track>, showingTrack: Binding<Track?>) {
        _showingTrack = showingTrack
        self.fetchRequest = fetchRequest
    }
    
    var body: some View {
        HStack {
            ForEach(tracks) { track in
                Button {
                    showingTrack = track
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .foregroundColor(Color(.systemFill))
                            .frame(height: 32)
                        if let systemImage = track.systemImage {
                            Text("\(Image(systemName: systemImage))")
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
    }
}

struct TracksRow_Previews: PreviewProvider {
    static var previews: some View {
        TracksRow(showingTrack: .constant(nil))
    }
}