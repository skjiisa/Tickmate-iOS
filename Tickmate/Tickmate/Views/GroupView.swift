//
//  GroupView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 5/14/21.
//

import SwiftUI

struct GroupView: View {
    
    //MARK: Properties
    
    @FetchRequest(entity: Track.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Track.index, ascending: true)])
    private var allTracks: FetchedResults<Track>
    
    @EnvironmentObject private var trackController: TrackController
    
    @ObservedObject var group: TrackGroup
    
    @State private var selectedTracks = Set<Track>()
    
    //MARK: Body
    
    var body: some View {
        Form {
            Section(header: Text("Name")) {
                TextField("Name", text: $group.wrappedName)
            }
            
            Section(header: Text("Tracks")) {
                ForEach(allTracks) { track in
                    TrackRow(track: track, selectedTracks: $selectedTracks)
                }
            }
        }
        .navigationTitle("Group details")
        .onAppear {
            guard let tracks = group.tracks as? Set<Track> else { return }
            selectedTracks = tracks
        }
        .onDisappear {
            withAnimation {
                group.tracks = selectedTracks as NSSet
            }
            // If we try using the environment's moc to save, this will
            // crash the app if the user makes this view disappear by
            // dismissing the sheet. I'm guessing this is because of
            // the environment disappearing too, deallocating the moc.
            trackController.scheduleSave()
        }
    }
    
    //MARK: TrackRew
    
    struct TrackRow: View {
        var track: Track
        @Binding var selectedTracks: Set<Track>
        
        var body: some View {
            Button {
                withAnimation(.interactiveSpring()) {
                    selectedTracks.toggle(track)
                }
            } label: {
                HStack {
                    Text(track.name ?? "New Track")
                    if selectedTracks.contains(track) {
                        Spacer()
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                            .transition(.scale)
                    }
                }
            }
            .foregroundColor(.primary)
        }
    }
}

struct GroupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GroupView(group: PersistenceController.preview.previewGroup!)
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
