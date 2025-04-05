//
//  ExportTracksSelectionView.swift
//  Tickmate
//
//  Created by Elaine Lyons on 3/27/24.
//

import SwiftUI
import SwiftDate

// The original version of this file was written by Trae using Claude-3.5-Sonnet

struct ExportTracksSelectionView: View {
    @EnvironmentObject private var trackController: TrackController
    
    @State private var selectedTracks: Set<Track> = []
    @State private var allAreSelected: Bool = false
    @State private var csv: CSV?
    
    private struct CSV: Identifiable {
        let url: URL
        var id: URL { url }
    }
    
    private var allTracks: [Track] {
        trackController.fetchedResultsController.fetchedObjects ?? []
    }
    
    var body: some View {
        List {
            Section {
                Button(allAreSelected ? "Deselect All" : "Select All") {
                    if allAreSelected {
                        selectedTracks.removeAll()
                        allAreSelected = false
                    } else {
                        selectedTracks = Set(allTracks)
                        allAreSelected = true
                    }
                }
            }
            
            Section {
                ForEach(allTracks) { track in
                    Toggle(isOn: Binding(
                        get: { selectedTracks.contains(track) },
                        set: { isSelected in
                            if isSelected {
                                selectedTracks.insert(track)
                                if selectedTracks.count == allTracks.count {
                                    allAreSelected = true
                                }
                            } else {
                                allAreSelected = false
                                selectedTracks.remove(track)
                            }
                        }
                    )) {
                        HStack {
                            if let systemImage = track.systemImage {
                                Image(systemName: systemImage)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(6)
                                    .frame(width: 36, height: 36)
                                    .foregroundColor(track.lightText ? .white : .black)
                                    .background(
                                        Color(rgb: Int(track.color))
                                            .cornerRadius(4)
                                    )
                            }
                            Text(track.name ?? "Unnamed Track")
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Tracks")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Export") {
                    exportSelectedTracksToCSV()
                }
                .disabled(selectedTracks.isEmpty)
            }
        }
        .onAppear {
            // Select all tracks by default
            selectedTracks = Set(allTracks)
            allAreSelected = true
        }
        .sheet(item: $csv) { csv in
            ShareSheet(activityItems: [csv.url])
        }
    }
    
    
    private func exportSelectedTracksToCSV() {
        let tracks = Array(selectedTracks)
        var csvString = "Date," + tracks.map { $0.name ?? "Unnamed Track" }.joined(separator: ",") + "\n"
        
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        
        // Find the earliest tick date across all selected tracks
        var earliestDay = 0
        for track in tracks {
            let controller = trackController.tickController(for: track)
            if let oldestDays = controller.oldestTickDate() {
                earliestDay = max(earliestDay, oldestDays)
            }
        }
        
        // Generate CSV from earliest date to today
        for day in (0...earliestDay).reversed() {
            let date = today - day.days
            let dateString = dateFormatter.string(from: date)
            let tickCounts = tracks.map { track -> String in
                let controller = trackController.tickController(for: track)
                let count = controller.tickCount(for: day)
                return track.multiple ? String(count) : (count > 0 ? "1" : "0")
            }
            csvString += dateString + "," + tickCounts.joined(separator: ",") + "\n"
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("tickmate_export.csv")
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            csv = CSV(url: fileURL)
        } catch {
            print("Error saving CSV: \(error)")
        }
    }
}

#if DEBUG
struct ExportTracksSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExportTracksSelectionView()
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(TrackController(preview: true))
    }
}
#endif
