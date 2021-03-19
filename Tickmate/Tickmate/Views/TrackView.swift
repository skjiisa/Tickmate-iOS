//
//  TrackView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/23/21.
//

import SwiftUI

struct TrackView: View {
    @Environment(\.managedObjectContext) private var moc
    
    @EnvironmentObject private var vcContainer: ViewControllerContainer
    @EnvironmentObject private var trackController: TrackController
    
    @ObservedObject var track: Track
    @Binding var selection: Track?
    let sheet: Bool
    
    @State private var draftTrack = TrackRepresentation()
    @State private var enabled = true
    @State private var initialized = false
    @State private var showingSymbolPicker = false
    @State private var showDelete = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Enabled", isOn: $enabled)
            }
            
            Section(header: Text("Name")) {
                TextField("Name", text: $draftTrack.name)
            }
            
            Section(header: Text("Settings")) {
                Toggle(isOn: $draftTrack.multiple) {
                    TextWithCaption(
                        text: "Allow multiple",
                        caption: "Multiple ticks on a day will be counted."
                            + " Long press to decrease counter.")
                }
                
                Toggle(isOn: $draftTrack.reversed.animation()) {
                    TextWithCaption(
                        text: "Reversed",
                        caption: "Days will be ticked by default."
                            + " Tapping a day will untick it."
                            + " Good for tracking abstaining from bad habits.")
                }
                
                if draftTrack.reversed {
                    DatePicker(selection: $draftTrack.startDate, displayedComponents: [.date]) {
                        TextWithCaption(
                            text: "Start date",
                            caption: "Days after this will automatically be ticked unless you untick them.")
                    }
                }
                
                ColorPicker("Color", selection: $draftTrack.color, supportsOpacity: false)
                
                NavigationLink(
                    destination: SymbolPicker(selection: $draftTrack.systemImage),
                    isActive: $showingSymbolPicker) {
                    HStack {
                        Text("Symbol")
                        Spacer()
                        if let symbol = draftTrack.systemImage {
                            Image(systemName: symbol)
                                .imageScale(.large)
                        }
                    }
                }
                .onChange(of: draftTrack.systemImage) { value in
                    showingSymbolPicker = false
                }
            }
            
            Section {
                Button {
                    showDelete = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete")
                        Spacer()
                    }
                }
                .accentColor(.red)
            }
            .actionSheet(isPresented: $showDelete) {
                ActionSheet(
                    title: Text("Are you sure you want to delete \(draftTrack.name.isEmpty ? "this track" : draftTrack.name)?"),
                    buttons: [
                        .destructive(Text("Delete"), action: delete),
                        .cancel()
                    ])
            }
        }
        .environment(\.editMode, $vcContainer.editMode)
        .navigationTitle("Track details")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                StateEditButton(editMode: $vcContainer.editMode, doneText: "Save") {
                    if vcContainer.editMode == .inactive {
                        save()
                    }
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                if sheet || vcContainer.editMode.isEditing {
                    Button(vcContainer.editMode.isEditing ? "Cancel" : "Done") {
                        vcContainer.editMode.isEditing ? cancel() : (selection = nil)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(vcContainer.editMode.isEditing)
        .onChange(of: draftTrack) { value in
            vcContainer.editMode = value == track ? .inactive : .active
        }
        .onAppear {
            if !initialized {
                draftTrack.load(track: track)
                enabled = track.enabled
                initialized = true
            }
        }
        .onDisappear {
            if enabled != track.enabled {
                track.enabled = enabled
                PersistenceController.save(context: moc)
            }
            vcContainer.deactivateEditMode()
        }
    }
    
    private func save() {
        let oldStartDate = track.startDate
        draftTrack.save(to: track)
        if track.startDate != oldStartDate {
            trackController.loadTicks(for: track)
        }
        PersistenceController.save(context: moc)
    }
    
    private func cancel() {
        withAnimation {
            draftTrack.load(track: track)
            // In case the user entered edit mode without making any changes,
            // which would mean onChange(of: draftTrack) wouldn't get called.
            vcContainer.editMode = draftTrack == track ? .inactive : .active
        }
    }
    
    private func delete() {
        selection = nil
        trackController.delete(track: track, context: moc)
        PersistenceController.save(context: moc)
    }
}

struct TrackView_Previews: PreviewProvider {
        
    static var track: Track = {
        try! PersistenceController.preview.container.viewContext.fetch(Track.fetchRequest()).first as! Track
    }()
    
    static var previews: some View {
        NavigationView {
            TrackView(track: track, selection: .constant(nil), sheet: false)
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environmentObject(ViewControllerContainer())
                .environmentObject(TrackController())
        }
    }
}
