//
//  TrackView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/23/21.
//

import SwiftUI

struct TrackView: View {
    
    @Environment(\.managedObjectContext) private var moc
    
    @EnvironmentObject private var trackController: TrackController
    
    @ObservedObject var track: Track
    
    @StateObject private var draftTrack = TrackRepresentation()
    @State private var initialized = false
    @State private var editMode = false
    
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
            }
            .disabled(!editMode)
        }
        .navigationTitle("Track details")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(editMode ? "Done" : "Edit") {
                    if editMode {
                        save()
                    }
                    withAnimation {
                        editMode.toggle()
                    }
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                if editMode {
                    Button("Cancel") {
                        cancel()
                        withAnimation {
                            editMode = false
                        }
                    }
                }
            }
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
    }
    
    private func cancel() {
        draftTrack.load(track: track)
    }
}

struct TrackView_Previews: PreviewProvider {
    
    static var color = Color(hue: Double.random(in: 0...1), saturation: 1, brightness: 1)
    
    static var previews: some View {
        NavigationView {
            TrackView(track: Track(name: "Test Track", color: Int32(color.rgb), context: PersistenceController.preview.container.viewContext))
        }
    }
}