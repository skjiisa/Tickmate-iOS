//
//  TracksView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/19/21.
//

import SwiftUI
import SwiftDate

struct TracksView: View {
    
    @Environment(\.managedObjectContext) private var moc
    @FetchRequest(
        entity: Track.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Track.name, ascending: true)])
    private var tracks: FetchedResults<Track>
    
    @EnvironmentObject private var trackController: TrackController
    
    @State private var showingTrack: Track?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Rectangle()
                    .opacity(0)
                    .frame(width: 80, height: 32)
                ForEach(tracks) { track in
                    Button {
                        showingTrack = track
                        UISelectionFeedbackGenerator().selectionChanged()
                    } label: {
                        ZStack {
                            Rectangle()
                                .foregroundColor(Color(.systemFill))
                                .cornerRadius(3)
                                .frame(height: 32)
                            if let systemImage = track.systemImage {
                                Image(systemName: systemImage)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    .onAppear {
                        trackController.loadTicks(for: track)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .sheet(item: $showingTrack) { track in
                NavigationView {
                    TrackView(track: track, selection: $showingTrack)
                }
            }
            
            Divider()
            
            ScrollViewReader { proxy in
                List {
                    Button("Go to bottom") {
                        proxy.scrollTo(0)
                    }
                    
                    ForEach(0..<365) { dayComplement in
                        HStack {
                            let day = 364 - dayComplement
                            trackController.dayLabel(day: day)
                                .frame(width: 80, alignment: .leading)
                            ForEach(tracks) { track in
                                TickView(track: track, day: day)
                            }
                        }
                    }
                    
                    Button("New") {
                        // This button is just for testing and will be removed
                        let track = Track(context: moc)
                        track.name = String(UUID().uuidString.dropLast(28))
                        track.color = Int32(Color(hue: Double.random(in: 0...1), saturation: 1, brightness: 1).rgb)
                        track.systemImage = SymbolsList.randomElement()
                    }
                    .id(0)
                }
                .listStyle(PlainListStyle())
                .padding(0)
                .onAppear {
                    proxy.scrollTo(0)
                }
            }
        }
        .navigationBarTitle("Tickmate", displayMode: .inline)
    }
}

struct TickView: View {
    
    @EnvironmentObject private var trackController: TrackController
    
    let track: Track
    let day: Int
    
    private var color: Color {
        trackController.ticks(on: day, for: track).isEmpty ? Color(.systemFill) : Color(rgb: Int(track.color))
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(color)
                .cornerRadius(3)
        }
        .onTapGesture {
            trackController.tick(day: day, for: track)
            UISelectionFeedbackGenerator().selectionChanged()
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
