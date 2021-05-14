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
    
    @AppStorage(Defaults.onboardingComplete.rawValue) private var onboardingComplete: Bool = false
    
    @StateObject private var trackController = TrackController()
    @StateObject private var vcContainer = ViewControllerContainer()
    
    @State private var showingSettings = false
    @State private var showingTracks = false
    @State private var scrollToBottomToggle = false
    @State private var showingOnboarding = false
    
    var body: some View {
        NavigationView {
            TabView {
                TicksView(scrollToBottomToggle: scrollToBottomToggle)
                TicksView(scrollToBottomToggle: scrollToBottomToggle)
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
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
