//
//  TracksView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/19/21.
//

import SwiftUI
import SFSafeSymbols
import SwiftDate

struct TracksView: View {
    
    @Environment(\.managedObjectContext) private var moc
    @FetchRequest(
        entity: Track.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Track.name, ascending: true)])
    private var tracks: FetchedResults<Track>
    
    @EnvironmentObject private var trackController: TrackController
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Rectangle()
                    .opacity(0)
                    .frame(width: 80, height: 32)
                ForEach(tracks) { (track: Track) in
                    ZStack {
                        Rectangle()
                            .foregroundColor(.blue)
                            .cornerRadius(3)
                            .frame(height: 32)
                        if let systemImage = track.systemImage {
                            Image(systemName: systemImage)
                        } else {
                            Text(track.name ?? "nil")
                        }
                    }
                    .onAppear {
                        trackController.loadTicks(for: track)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            
            Divider()
            
            ScrollViewReader { proxy in
                List {
                    Button("Go to bottom") {
                        proxy.scrollTo(0)
                    }
                    
                    ForEach(0..<365) { day in
                        HStack {
                            Text("\(364 - day)")
                                .frame(width: 80)
                            ForEach(tracks) { track in
                                TickView(track: track, day: 364 - day)
                            }
                        }
                    }
                    
                    Button("New") {
                        // This button is just for testing and will be removed
                        let track = Track(context: moc)
                        track.name = UUID().uuidString
                        track.systemImage = SFSymbol.allCases.randomElement()?.rawValue
                        
                        let tick1 = Tick(track: track, context: moc)
                        tick1.timestamp = Date() - 1.days
                        let tick3 = Tick(track: track, context: moc)
                        tick3.timestamp = Date() - 3.days
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
        trackController.ticks(for: track, on: day).isEmpty ? .secondary : .accentColor
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(color)
                .cornerRadius(3)
            if let systemImage = track.systemImage {
                Image(systemName: systemImage)
            }
        }
    }
}

struct TracksView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TracksView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
