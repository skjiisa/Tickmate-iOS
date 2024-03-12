//
//  ArchivedTracksView.swift
//  Tickmate
//
//  Created by Elaine Lyons on 3/9/24.
//

import SwiftUI

struct ArchivedTracksView: View {
    
    @Environment(\.managedObjectContext) private var moc
    @State private var editMode = EditMode.inactive
    
    @EnvironmentObject private var trackController: TrackController
    
    @State private var selection: Track?
    
    private var tracks: [Track] {
        trackController.archivedTracksFRC.fetchedObjects ?? []
    }
    
    var body: some View {
        Form {
            Section {
                ForEach(tracks) { track in
                    TrackCell(track: track, selection: $selection, shouldShowToggle: false)
                }
                .onDelete(perform: self.delete(_:))
            }
        }
        .environment(\.editMode, $editMode)
        .navigationTitle("Archived tracks")
        // TODO: Add bulk unarchiving?
        // As far as I can tell, onDelete is only available with ForEach,
        // but multiselect is only available with List, so you can only
        // do one or the other???
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                StateEditButton(editMode: $editMode)
            }
        }
    }
    
    private func delete(_ indexSet: IndexSet) {
        indexSet.map { tracks[$0] }.forEach {
            trackController.delete(track: $0, context: moc)
        }
        trackController.scheduleSave()
        trackController.scheduleTimelineRefresh()
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
