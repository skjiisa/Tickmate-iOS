//
//  ArchivedTracksView.swift
//  Tickmate
//
//  Created by Elaine Lyons on 3/9/24.
//

import SwiftUI

struct ArchivedTracksView: View {
    
    @Environment(\.managedObjectContext) private var moc
    
    @EnvironmentObject private var trackController: TrackController
    
    @State private var selection: Track?
    
    private var tracks: [Track] {
        trackController.archivedTracksFRC.fetchedObjects ?? []
    }
    
    var body: some View {
        Form {
            Section {
                ForEach(tracks) { track in
                    // TODO: Remove `enabled` toggle
                    TrackCell(track: track, selection: $selection)
                }
            }
        }
        .navigationTitle("Archived tracks")
        // TODO: Add edit mode for bulk unarchiving.
    }
}

#Preview {
    NavigationView {
        ArchivedTracksView()
    }
    .navigationViewStyle(StackNavigationViewStyle())
    // TODO: Make unified .previewEnvironment() modifier?
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    .environmentObject(TrackController(preview: true))
    .environmentObject(ViewControllerContainer())
}
