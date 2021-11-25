//
//  ContentView.swift
//  Tickmate
//
//  Created by Elaine Lyons on 2/19/21.
//

import SwiftUI
import Introspect

//MARK: ContenView

struct ContentView: View {
    
    //MARK: External Properties
    
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
    
    //MARK: State properties
    
    @StateObject private var trackController = TrackController()
    @StateObject private var groupController = GroupController()
    @StateObject private var vcContainer = ViewControllerContainer()
    @StateObject private var storeController = StoreController()
    @StateObject private var pagingController = PagingController()
    
    @State private var showingSettings = false
    @State private var showingTracks = false
    @State private var scrollToBottomToggle = false
    @State private var showingOnboarding = false
    
    @State private var translation: CGFloat = 0.0
    @State private var pageChange = 0
    
    //MARK: Computed Properties
    
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
    
    private var titles: [String] {
        [
            showingAllTracks ? "Tickmate" : nil,
            showingUngroupedTracks ? "Ungrouped" : nil,
        ].compactMap { $0 }
        + groups.map { $0.displayName }
    }
    
    private var sheetsOnMainView: Bool {
        guard #available(iOS 15, *) else { return false }
        return true
    }
    
    //MARK: Views
    
    private var titleMask: some View {
        VStack {
            Rectangle().fill(LinearGradient(gradient: Gradient(colors: [.clear, .black, .black, .black, .clear]), startPoint: .leading, endPoint: .trailing))
                .padding(.horizontal, 50)
            Rectangle().foregroundColor(.black)
        }
    }
    
    private var titlesView: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                //TODO: Add Tickmate and Ungrouped
                HStack(spacing: 0) {
                    ForEach(groups) { group in
                        VStack(spacing: 0) {
                            Text(group.displayName)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            TracksRow(group: group)
                                .padding(.leading, 88)
                                .padding(.trailing)
                                .padding(.top, 16)
                                .padding(.bottom, 4)
                            
                            Divider()
                        }
                        .frame(width: geo.size.width)
                    }
                }
            }
            .introspectScrollView { scrollView in
                pagingController.load(titleScrollView: scrollView)
            }
            .frame(width: geo.size.width)
            .padding(.top, 10)
            .mask(titleMask)
        }
    }
    
    //MARK: Body
    
    var body: some View {
        NavigationView {
            /*
            PageView(pageCount: pageCount, currentIndex: $page, offset: $translation) {
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
             */
            // This Group is just here so the indentation stays the same as before.
            Group {
                PagingView(groups: groups)
                    .padding(.top, 40)
            }
            .navigationBarTitle("", displayMode: .inline)
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
        .overlay(titlesView)
        .navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(trackController)
        .environmentObject(groupController)
        .environmentObject(pagingController)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            trackController.saveIfScheduled()
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
        
        //MARK: Sheets
        
        // Maybe this is more of an SDK thing and not an iOS 15 thing and
        // this can be used instead of the EmptyViews in iOS 14 too.
        // More testing needed.
        .if(sheetsOnMainView) { view in
            view.sheet(isPresented: $showingTracks) {
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
            .sheet(isPresented: $showingSettings) {
                scrollToBottomToggle.toggle()
            } content: {
                NavigationView {
                    SettingsView(showing: $showingSettings)
                }
                .environmentObject(trackController)
                .environmentObject(storeController)
            }
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView(showing: $showingOnboarding)
                    .environment(\.managedObjectContext, moc)
                    .environmentObject(trackController)
            }
        }
        
        if .iOS14 {
            // See https://write.as/angelo/stupid-swiftui-tricks-debugging-sheet-dismissal
            // for why the sheets are attached to EmptyViews
            EmptyView().sheet(isPresented: $showingTracks) {
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
            
            EmptyView().sheet(isPresented: $showingSettings) {
                scrollToBottomToggle.toggle()
            } content: {
                NavigationView {
                    SettingsView(showing: $showingSettings)
                }
                .environmentObject(trackController)
                .environmentObject(storeController)
            }
            
            EmptyView().sheet(isPresented: $showingOnboarding) {
                OnboardingView(showing: $showingOnboarding)
                    .environment(\.managedObjectContext, moc)
                    .environmentObject(trackController)
            }
        }
    }
    
    //MARK: Functions
    
    private func updatePage(pageInserted: Bool) {
        if groups.count > 0 {
            page += pageInserted ? 1 : (page == 0 ? 0 : -1)
        }
    }
    
}

//MARK: Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
