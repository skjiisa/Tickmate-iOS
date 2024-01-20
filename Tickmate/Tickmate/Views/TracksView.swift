//
//  TracksView.swift
//  Tickmate
//
//  Created by Elaine Lyons on 2/28/21.
//

import SwiftUI

//MARK: TracksView

struct TracksView: View {
    
    //MARK: Properties
    
    @Environment(\.managedObjectContext) private var moc
    // The environment EditMode is buggy, so using a custom @State property instead
    @State private var editMode = EditMode.inactive
    
    @AppStorage(StoreController.Products.groups.rawValue) private var groupsUnlocked: Bool = false
    
    @EnvironmentObject private var trackController: TrackController
    
    @Binding var showing: Bool
    
    @State private var selection: Track?
    @State private var showingPresets = false
    
    private var tracks: [Track] {
        trackController.fetchedResultsController.fetchedObjects ?? []
    }
    
    //MARK: Body
    
    var body: some View {
        Form {
            Section(footer: Text(
                        groupsUnlocked
                            ? "Swipe left and right on the main screen to change group"
                            : "Unlock the groups upgrade from the settings page")) {
                NavigationLink("Groups", destination: GroupsView())
            }
            .disabled(!groupsUnlocked)
            
            ForEach(tracks) { track in
                TrackCell(track: track, selection: $selection)
            }
            .onDelete(perform: delete)
            .onMove(perform: move)
            .animation(.easeInOut(duration: 0.25))
            
            Section {
                Button("Create new track") {
                    withAnimation {
                        let newTrack = trackController.newTrack(index: (tracks.last?.index ?? -1) + 1, context: moc)
                        select(track: newTrack, delay: 0.25)
                    }
                }
                .foregroundColor(.accentColor)
                
                Button("Add preset track") {
                    showingPresets = true
                }
                .foregroundColor(.accentColor)
            }
        }
        .environment(\.editMode, $editMode)
        .navigationTitle("Tracks")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                StateEditButton(editMode: $editMode)
            }
            ToolbarItem(placement: .cancellationAction) {
                if !editMode.isEditing {
                    Button("Done") {
                        showing = false
                    }
                }
            }
        }
        .sheet(isPresented: $showingPresets) {
            NavigationView {
                PresetTracksView { trackRepresentation in
                    showingPresets = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation {
                            let newTrack = trackController.newTrack(from: trackRepresentation, index: (tracks.last?.index ?? -1) + 1, context: moc)
                            select(track: newTrack, delay: 0.25)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingPresets = false
                        }
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    //MARK: Functions
    
    private func delete(_ indexSet: IndexSet) {
        indexSet.map { tracks[$0] }.forEach {
            trackController.delete(track: $0, context: moc)
        }
        trackController.scheduleSave()
        trackController.scheduleTimelineRefresh()
    }
    
    private func move(_ indices: IndexSet, newOffset: Int) {
        var trackIndices = tracks.enumerated().map { $0.offset }
        trackIndices.move(fromOffsets: indices, toOffset: newOffset)
        trackIndices.enumerated().compactMap { offset, element in
            element != offset ? (tracks[element], Int16(offset)) : nil
        }.forEach { $0.index = $1 }
        
        PersistenceController.save(context: moc)
        trackController.scheduleTimelineRefresh()
    }
    
    private func select(track: Track, delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            selection = track
        }
    }
}

//MARK: TrackCell

struct TrackCell: View {
    
    @Environment(\.managedObjectContext) private var moc
    
    @ObservedObject var track: Track
    @Binding var selection: Track?
    
    private var caption: String {
        [track.multiple ? "Multiple" : nil, track.reversed ? "Reversed" : nil].compactMap { $0 }.joined(separator: ", ")
    }
    
    private var background: some View {
        Color(rgb: Int(track.color))
            .cornerRadius(8)
    }
    
    var body: some View {
        NavigationLink(
            destination: TrackView(track: track, selection: $selection, sheet: false),
            tag: track,
            selection: $selection) {
            HStack {
                if let systemImage = track.systemImage {
                    Image(systemName: systemImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .padding()
                        .background(background)
                        .foregroundColor(track.lightText ? .white : .black)
                }
                TextWithCaption(text: track.name ?? "", caption: caption)
                Spacer(minLength: 0)
                Toggle(isOn: $track.enabled) {
                    EmptyView()
                }
                .onChange(of: track.enabled) { _ in
                    PersistenceController.save(context: moc)
                }
            }
        }
        .foregroundColor(track.enabled ? .primary : .secondary)
    }
}

//MARK: Previews

struct TracksView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TracksView(showing: .constant(true))
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environmentObject(TrackController(preview: true))
        }
    }
}
