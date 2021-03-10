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
    
    @State private var showingTracks = false
    @State private var scrollToBottomToggle = false
    
    @State private var showingSettings = false
    @State private var timeOffset: Date = Date()
    @State private var customDayStartChanged = false

    var body: some View {
        NavigationView {
//            Group {
            TicksView(scrollToBottomToggle: scrollToBottomToggle)
//            }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingTracks = true
                        } label: {
                            Image(systemName: "text.justify")
                                .imageScale(.large)
                        }
                        .sheet(isPresented: $showingTracks) {
                            NavigationView {
                                TracksView(showing: $showingTracks)
                            }
                            .environment(\.managedObjectContext, moc)
                            .environmentObject(trackController)
                        }
                    }
                    ToolbarItem(placement: .navigation) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gear")
                                .imageScale(.large)
                        }
                        .sheet(isPresented: $showingSettings) {
                            scrollToBottomToggle.toggle()
                            if customDayStartChanged {
                                updateCustomDayStart()
                                customDayStartChanged = false
                            }
                            trackController.updateWeekStartDay()
                        } content: {
                            NavigationView {
                                SettingsView(showing: $showingSettings, timeOffset: $timeOffset, customDayStartChanged: $customDayStartChanged)
                            }
                            .environmentObject(trackController)
                        }
                    }
                }
        }
        .environmentObject(trackController)
        .onAppear(perform: loadTimeOffset)
    }
    
    private func loadTimeOffset() {
        if let date = DateInRegion(components: { dateComponents in
            dateComponents.minute = UserDefaults.standard.integer(forKey: Defaults.customDayStartMinutes.rawValue)
        }, region: .current) {
            timeOffset = date.date
        }
    }
    
    private func updateCustomDayStart() {
        // If this change is performed while SettingsView is showing (such
        // as in an onChange), TicksView will reload and ContentView will
        // try to re-present SettingsView for some reason, leading to a bug
        // where the settings button no longer works. This happens whether
        // the toolbar and sheets are in ContentView or TicksView.
        let components = timeOffset.in(region: .current).dateComponents
        let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        trackController.setCustomDayStart(minutes: minutes)
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
