//
//  TrackView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/23/21.
//

import SwiftUI

struct TrackView: View {
    @Environment(\.managedObjectContext) private var moc
    
    @ObservedObject var track: Track
    @Binding var selection: Track?
    let sheet: Bool
    
    @State private var draftTrack = TrackRepresentation()
    @State private var initialized = false
    @State private var editMode = false
    @State private var showingSymbolPicker = false
    @State private var showDelete = false
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $draftTrack.name)
            }
            
            Section(header: Text("Settings")) {
                Toggle(isOn: $draftTrack.multiple) {
                    TextWithCaption(
                        text: "Allow multiple",
                        caption: "Multiple ticks on a day will be counted."
                            + " Long press to decrease counter.")
                }
                
                Toggle(isOn: $draftTrack.reversed) {
                    TextWithCaption(
                        text: "Reversed",
                        caption: "Days will be ticked by default."
                            + " Tapping a day will untick it."
                            + " Good for tracking bad habits.")
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
        .navigationTitle("Track details")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(editMode ? "Save" : "Edit") {
                    if editMode {
                        save()
                    }
                    withAnimation {
                        editMode.toggle()
                    }
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                if sheet {
                    Button(editMode ? "Cancel" : "Done") {
                        editMode ? cancel() : (selection = nil)
                    }
                }
            }
        }
        .onChange(of: draftTrack) { value in
            editMode = value != track
        }
        .onAppear {
            if !initialized {
                draftTrack.load(track: track)
                initialized = true
            }
        }
    }
    
    private func save() {
        draftTrack.save(to: track)
        PersistenceController.save(context: moc)
    }
    
    private func cancel() {
        withAnimation {
            draftTrack.load(track: track)
            editMode = draftTrack != track
        }
    }
    
    private func delete() {
        selection = nil
        moc.delete(track)
        PersistenceController.save(context: moc)
    }
}

struct TrackView_Previews: PreviewProvider {
        
    static var track: Track = {
        try! PersistenceController.preview.container.viewContext.fetch(Track.fetchRequest()).first as! Track
    }()
    
    static var previews: some View {
        NavigationView {
            TrackView(track: track, selection: .constant(nil), sheet: true)
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
