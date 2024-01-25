//
//  GroupView.swift
//  Tickmate
//
//  Created by Elaine Lyons on 5/14/21.
//

import SwiftUI
import SwiftUIIntrospect

struct GroupView: View {
    
    //MARK: Properties
    
    @FetchRequest(entity: Track.entity(), sortDescriptors: TrackController.sortDescriptors)
    private var allTracks: FetchedResults<Track>
    
    @EnvironmentObject private var vcContainer: ViewControllerContainer
    @EnvironmentObject private var trackController: TrackController
    
    @ObservedObject var group: TrackGroup
    
    @State private var name = ""
    @State private var selectedTracks = Set<Track>()
    @State private var fixTextField = false
    
    //MARK: Body
    
    var body: some View {
        Form {
            Section(header: Text("Name")) {
                TextField("Name", text: $name)
                // TODO: Replace with .submitLabel(.done) when iOS 14 is dropped
                    .introspect(.textField, on: .iOS(.v14, .v15, .v16, .v17)) { textField in
                        textField.returnKeyType = .done
                    }
                    .id(fixTextField)
                    .onAppear {
                        // iOS 15 doesn't seem to like actually loading the text field's text on appear
                        guard #available(iOS 15, *) else { return }
                        guard #unavailable(iOS 17) else { return }
                        guard !fixTextField else { return }
                        fixTextField = true
                    }
            }
            
            Section(header: Text("Tracks")) {
                ForEach(allTracks) { track in
                    TrackRow(track: track, selectedTracks: $selectedTracks)
                }
            }
        }
        .navigationTitle("Group details")
        .onAppear {
            name = group.wrappedName
            if let tracks = group.tracks as? Set<Track> {
                selectedTracks = tracks
            }
        }
        .onDisappear {
            withAnimation {
                group.name = name
                group.tracks = selectedTracks as NSSet
                // If we try using the environment's moc to save, this will
                // crash the app if the user makes this view disappear by
                // dismissing the sheet. I'm guessing this is because of
                // the environment disappearing too, deallocating the moc.
                trackController.scheduleSave()
            }
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
                            #if os(iOS)
                            .foregroundColor(.accentColor)
                            #endif
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
