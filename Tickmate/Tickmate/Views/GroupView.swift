//
//  GroupView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 5/14/21.
//

import SwiftUI

struct GroupView: View {
    
    @FetchRequest(entity: Track.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Track.index, ascending: true)])
    private var tracks: FetchedResults<Track>
    
    @ObservedObject var group: TrackGroup
    
    @State private var draftGroup = GroupRepresentation()
    
    var body: some View {
        Form {
            Section(header: Text("Name")) {
                TextField("Name", text: $draftGroup.name)
            }
            
            Section(header: Text("Tracks")) {
                ForEach(tracks) { track in
                    Button {
                        draftGroup.tracks.toggle(track)
                    } label: {
                        HStack {
                            Text(track.name ?? "New Track")
                            if draftGroup.tracks.contains(track) {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            
            // I don't know why, but draftGroup.tracks.contains(track)
            // doesn't update unless there's another check somewhere else.
            if draftGroup.loaded {
                EmptyView()
            }
        }
        .navigationTitle("Group details")
        .onAppear {
            draftGroup.load(group)
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
