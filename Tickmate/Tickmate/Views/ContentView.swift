//
//  ContentView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/19/21.
//

import SwiftUI
import Introspect

struct ContentView: View {
    
    @Environment(\.managedObjectContext) private var moc
    
    @FetchRequest(
        entity: TrackGroup.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TrackGroup.index, ascending: true)],
        predicate: NSPredicate(format: "tracks.@count > 0"))
    private var groups: FetchedResults<TrackGroup>
    
    private var ungroupedTracksFetchRequest = FetchRequest<Track>(
        entity: Track.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Track.index, ascending: true)],
        predicate: NSPredicate(format: "enabled == YES AND groups.@count == 0"),
        animation: .default)
    
    @AppStorage(Defaults.showAllTracks.rawValue) private var showAllTracks = true
    @AppStorage(Defaults.showUngroupedTracks.rawValue) private var showUngroupedTracks = false
    @AppStorage(Defaults.onboardingComplete.rawValue) private var onboardingComplete: Bool = false
    @AppStorage(Defaults.groupPage.rawValue) private var page = 0
    
    @StateObject private var trackController = TrackController()
    @StateObject private var groupController = GroupController()
    @StateObject private var vcContainer = ViewControllerContainer()
    @StateObject private var storeController = StoreController()
    
    @State private var showingSettings = false
    @State private var showingTracks = false
    @State private var scrollToBottomToggle = false
    @State private var showingOnboarding = false
    
    private var showingAllTracks: Bool {
        showAllTracks || groups.count == 0 || !storeController.groupsUnlocked
    }
    
    private var showingUngroupedTracks: Bool {
        showUngroupedTracks && ungroupedTracksFetchRequest.wrappedValue.count > 0 && storeController.groupsUnlocked
    }
    
    private var pageCount: Int {
        storeController.groupsUnlocked
            ? groups.count + showAllTracks.int + showingUngroupedTracks.int
            : 1
    }
    
    var body: some View {
        NavigationView {
            PageView(pageCount: pageCount, currentIndex: $page) {
                if showingAllTracks {
                    TicksView(scrollToBottomToggle: scrollToBottomToggle)
                }
                
                if showingUngroupedTracks {
                    TicksView(fetchRequest: ungroupedTracksFetchRequest, scrollToBottomToggle: scrollToBottomToggle)
                }
                
                if storeController.groupsUnlocked {
                    ForEach(groups) { group in
                        TicksView(group: group, scrollToBottomToggle: scrollToBottomToggle)
                    }
                }
            }
            .navigationBarTitle("Tickmate", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingTracks = true
                    } label: {
                        Label("Tracks", systemImage: "text.justify")
                    }
                    .imageScale(.large)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                    .imageScale(.large)
                }
            }
            .onChange(of: showAllTracks, perform: updatePage)
            .onChange(of: showUngroupedTracks) { value in
                // If there are no ungrouped tracks, then nothing needs to change
                guard ungroupedTracksFetchRequest.wrappedValue.count > 0 else { return }
                updatePage(pageInserted: value)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(trackController)
        .environmentObject(groupController)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            trackController.scheduleSave(now: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            print("willEnterForeground")
            trackController.checkForNewDay()
        }
        .onAppear {
            groupController.trackController = trackController
            
            // There have been bugs with page numbers in the past.
            // This is just in case the page number gets bugged
            // and is scrolled past the edge.
            if page < 0 || (page >= pageCount) {
                page = 0
            }
            
            if !onboardingComplete {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    showingOnboarding = true
                }
            }
        }
        
        // See https://write.as/angelo/stupid-swiftui-tricks-debugging-sheet-dismissal
        // for why the sheets are attached to EmptyViews
        EmptyView()
            .sheet(isPresented: $showingTracks) {
                vcContainer.deactivateEditMode()
            } content: {
                NavigationView {
                    TracksView(showing: $showingTracks)
                }
                .environment(\.managedObjectContext, moc)
                .environmentObject(trackController)
                .environmentObject(groupController)
                .environmentObject(vcContainer)
                .introspectViewController { vc in
                    vc.presentationController?.delegate = vcContainer
                }
            }
        
        EmptyView()
            .sheet(isPresented: $showingSettings) {
                scrollToBottomToggle.toggle()
            } content: {
                NavigationView {
                    SettingsView(showing: $showingSettings)
                }
                .environmentObject(trackController)
                .environmentObject(storeController)
            }
        
        EmptyView()
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView(showing: $showingOnboarding)
                    .environment(\.managedObjectContext, moc)
                    .environmentObject(trackController)
            }
    }
    
    private func updatePage(pageInserted: Bool) {
        if groups.count > 0 {
            page += pageInserted ? 1 : (page == 0 ? 0 : -1)
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
