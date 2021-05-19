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
        sortDescriptors: [NSSortDescriptor(keyPath: \TrackGroup.name, ascending: true)])
    private var groups: FetchedResults<TrackGroup>
    
    @AppStorage(Defaults.showAllTracks.rawValue) private var showAllTracks = true
    @AppStorage(Defaults.onboardingComplete.rawValue) private var onboardingComplete: Bool = false
    
    @StateObject private var trackController = TrackController()
    @StateObject private var vcContainer = ViewControllerContainer()
    
    @State private var showingSettings = false
    @State private var showingTracks = false
    @State private var scrollToBottomToggle = false
    @State private var showingOnboarding = false
    @State private var page = 0
    
    var body: some View {
        NavigationView {
            PageView(pageCount: groups.count + (showAllTracks || groups.count == 0).int, currentIndex: $page) {
                if showAllTracks || groups.count == 0 {
                    TicksView(scrollToBottomToggle: scrollToBottomToggle)
                }
                
                ForEach(groups) { group in
                    TicksView(group: group, scrollToBottomToggle: scrollToBottomToggle)
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
            .onChange(of: showAllTracks) { value in
                if value,
                   groups.count > 0 {
                    // A page 0 was just inserted.
                    // Increment the page number to keep it on the same page.
                    page += 1
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(trackController)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            trackController.scheduleSave(now: true)
        }
        .onAppear {
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
            }
        
        EmptyView()
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView(showing: $showingOnboarding)
                    .environment(\.managedObjectContext, moc)
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
