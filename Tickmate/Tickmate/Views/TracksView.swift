//
//  TracksView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/19/21.
//

import SwiftUI
import SFSafeSymbols

struct TracksView: View {
    
    @Environment(\.managedObjectContext) private var moc
    @FetchRequest(
        entity: Track.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Track.name, ascending: true)])
    private var tracks: FetchedResults<Track>
    
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
                                // I have absolutely no idea why, but it doesn't work without this
                                if true {
                                    ZStack {
                                        Rectangle()
                                            .foregroundColor(.blue)
                                            .cornerRadius(3)
                                        if let systemImage = track.systemImage {
                                            Image(systemName: systemImage)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Button("New") {
                        let track = Track(context: moc)
                        track.name = UUID().uuidString
                        track.systemImage = SFSymbol.allCases.randomElement()?.rawValue
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

struct TracksView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TracksView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
