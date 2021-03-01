//
//  TicksView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/19/21.
//

import SwiftUI
import SwiftDate

struct TicksView: View {
    
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
                                TickView(day: day, track: track, tickController: trackController.tickController(for: track))
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
    
    let day: Int
    
    @ObservedObject var track: Track
    @ObservedObject var tickController: TickController
    
    private var color: Color {
        // If the day is ticked, use the track color. Otherwise, use
        // system fill. If the track is reversed, reverse the check.
        tickController.ticks(on: day).isEmpty != track.reversed ? Color(.systemFill) : Color(rgb: Int(track.color))
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(color)
                .cornerRadius(3)
            let count = tickController.ticks(on: day).count
            if count > 1 {
                Text("\(count)")
                    .foregroundColor(track.lightText ? .white : .black)
            }
        }
        .onTapGesture {
            tickController.tick(day: day)
            UISelectionFeedbackGenerator().selectionChanged()
        }
        // This long press feels too long, and setting
        // minimumDuration below 0.5 doesn't have an effect.
        //TODO: write custom gesture.
        .onLongPressGesture {
            guard track.multiple else { return }
            if tickController.untick(day: day) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        }
    }
}

struct TicksView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TicksView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environmentObject(TrackController())
        }
    }
}
