//
//  TracksView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/28/21.
//

import SwiftUI

struct TracksView: View {
    
    @Environment(\.managedObjectContext) private var moc
    @FetchRequest(
        entity: Track.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Track.index, ascending: true)])
    private var tracks: FetchedResults<Track>
    
    @EnvironmentObject private var trackController: TrackController
    
    @State private var selection: Track?
    
    var body: some View {
        List {
            ForEach(tracks) { track in
                TrackCell(track: track, selection: $selection)
            }
            .onDelete(perform: delete)
            .onMove(perform: move)
        }
        .navigationTitle("Tracks")
        .toolbar {
            EditButton()
        }
    }
    
    private func delete(_ indexSet: IndexSet) {
        indexSet.map { tracks[$0] }.forEach(moc.delete)
        PersistenceController.save(context: moc)
    }
    
    private func move(_ indices: IndexSet, newOffset: Int) {
        var trackIndices = tracks.enumerated().map { $0.offset }
        trackIndices.move(fromOffsets: indices, toOffset: newOffset)
        trackIndices.enumerated().compactMap { offset, element in
            element != offset ? (track: tracks[element], newIndex: Int16(offset)) : nil
        }.forEach { $0.track.index = $0.newIndex }
        
        PersistenceController.save(context: moc)
    }
}

struct TrackCell: View {
    
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
                Text("\(track.index)")
                TextWithCaption(text: track.name ?? "", caption: caption)
            }
        }
    }
}

struct TracksView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TracksView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environmentObject(TrackController())
        }
    }
}
