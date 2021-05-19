//
//  GroupView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 5/14/21.
//

import SwiftUI

struct GroupView: View {
    
    @Environment(\.managedObjectContext) private var moc
    
    @FetchRequest(entity: Track.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Track.index, ascending: true)])
    private var tracks: FetchedResults<Track>
    
    @ObservedObject var group: TrackGroup
    
    var body: some View {
        Form {
            Section(header: Text("Name")) {
                TextField("Name", text: $group.wrappedName)
            }
            
            Section(header: Text("Tracks")) {
                ForEach(tracks) { track in
                    Button {
                        group.mutableSetValue(forKey: "tracks").toggle(track)
                    } label: {
                        HStack {
                            Text(track.name ?? "New Track")
                            if group.tracks?.contains(track) ?? false {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .navigationTitle("Group details")
        .onDisappear {
            PersistenceController.save(context: moc)
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
