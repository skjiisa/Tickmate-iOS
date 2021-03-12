//
//  ContentView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/19/21.
//

import SwiftUI
import CoreData
import SwiftDate

struct ContentView: View {
    @Environment(\.managedObjectContext) private var moc
    
    @StateObject private var trackController = TrackController()
    
    @State private var showingSettings = false
    @State private var showingTracks = false
    @State private var scrollToBottomToggle = false
    
    var body: some View {
        NavigationView {
            TicksView(scrollToBottomToggle: scrollToBottomToggle)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingTracks = true
                        } label: {
                            Image(systemName: "text.justify")
                                .imageScale(.large)
                        }
                    }
                    ToolbarItem(placement: .navigation) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gear")
                                .imageScale(.large)
                        }
                    }
                }
        }
        .environmentObject(trackController)
        
        // See https://write.as/angelo/stupid-swiftui-tricks-debugging-sheet-dismissal
        // for why the sheets are attached to EmptyViews
        EmptyView()
            .sheet(isPresented: $showingTracks) {
                NavigationView {
                    TracksView(showing: $showingTracks)
                }
                .environment(\.managedObjectContext, moc)
                .environmentObject(trackController)
            }
        
        EmptyView()
            .sheet(isPresented: $showingSettings) {
                scrollToBottomToggle.toggle()
            } content: {
                NavigationView {
                    SettingsView(showing: $showingSettings)
                }
                .environmentObject(trackController)
            }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
