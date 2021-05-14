//
//  TrackView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/23/21.
//

import SwiftUI

struct TrackView: View {
    
    //MARK: Properties
    
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
    
    //MARK: Body
    
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
                    DatePicker(selection: $draftTrack.startDate, in: Date.distantPast...trackController.date, displayedComponents: [.date]) {
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
                Button("Delete") {
                    showDelete = true
                }
                .centered()
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
        .navigationTitle("Track details")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                StateEditButton(editMode: $vcContainer.editMode, doneText: "Save") {
                    if vcContainer.editMode == .inactive {
                        trackController.save(draftTrack, to: track, context: moc)
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
        .onChange(of: draftTrack) { _ in
            setEditMode()
        }
        .onChange(of: vcContainer.editMode) { value in
            if !value.isEditing {
                dismissKeyboard()
            }
        }
        .onAppear {
            if !initialized {
                draftTrack.load(track: track)
                enabled = track.enabled
                initialized = true
            } else {
                setEditMode()
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
    
    //MARK: Functions
    
    private func setEditMode() {
        vcContainer.editMode = draftTrack == track ? .inactive : .active
    }
    
    private func cancel() {
        if track.name == "New Track",
           track.ticks?.anyObject() == nil {
            // This is a brand new track. Delete it instead of exiting edit mode
            delete()
        } else {
            withAnimation {
                draftTrack.load(track: track)
                // In case the user entered edit mode without making any changes,
                // which would mean onChange(of: draftTrack) wouldn't get called.
                setEditMode()
            }
        }
    }
    
    private func delete() {
        selection = nil
        trackController.delete(track: track, context: moc)
        PersistenceController.save(context: moc)
    }
}

//MARK: Previews

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
