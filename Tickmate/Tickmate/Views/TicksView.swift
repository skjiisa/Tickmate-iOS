//
//  TicksView.swift
//  Tickmate
//
//  Created by Elaine Lyons on 2/19/21.
//

import SwiftUI
import SwiftDate
import SwiftUIIntrospect

//MARK: Ticks View

struct TicksView: View {
    
    @Environment(\.managedObjectContext) private var moc
    
    private var fetchRequest: FetchRequest<Track>
    private var tracks: FetchedResults<Track> {
        fetchRequest.wrappedValue
    }
    
    @AppStorage(Defaults.weekSeparatorLines.rawValue) private var weekSeparatorLines: Bool = true
    @AppStorage(Defaults.weekSeparatorSpaces.rawValue) private var weekSeparatorSpaces: Bool = true
    
    @EnvironmentObject private var groupController: GroupController
    @EnvironmentObject private var trackController: TrackController
    
    var scrollToBottomToggle: Bool = false
    
    @StateObject private var vcContainer = ViewControllerContainer()
    
    @State private var showingTrack: Track?
    
    init(scrollToBottomToggle: Bool = false) {
        self.scrollToBottomToggle = scrollToBottomToggle
        fetchRequest = FetchRequest(
            entity: Track.entity(),
            sortDescriptors: TrackController.sortDescriptors,
            predicate: NSPredicate(format: "enabled == YES"))
    }
    
    init(group: TrackGroup, scrollToBottomToggle: Bool = false) {
        self.scrollToBottomToggle = scrollToBottomToggle
        fetchRequest = FetchRequest(
            entity: Track.entity(),
            sortDescriptors: TrackController.sortDescriptors,
            predicate: NSPredicate(format: "enabled == YES AND %@ IN groups", group))
    }
    
    init(fetchRequest: FetchRequest<Track>, scrollToBottomToggle: Bool = false) {
        self.fetchRequest = fetchRequest
        self.scrollToBottomToggle = scrollToBottomToggle
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Rectangle()
                    .opacity(0)
                    .frame(width: 80, height: 32)
                ForEach(tracks) { track in
                    Button {
                        showingTrack = track
                        #if os(iOS)
                        UISelectionFeedbackGenerator().selectionChanged()
                        #endif
                    } label: {
                        ZStack {
                            #if os(iOS)
                            RoundedRectangle(cornerRadius: 3)
                                .foregroundColor(Color(.systemFill))
                            #elseif os(visionOS)
                            Color.clear
                            #endif
                            if let systemImage = track.systemImage {
                                Text("\(Image(systemName: systemImage))")
                            }
                        }
                        .frame(height: 32)
                    }
                    .foregroundColor(.primary)
                    .onAppear {
                        trackController.loadTicks(for: track)
                    }
                    #if os(visionOS)
                    .buttonStyle(.borderless)
                    #endif
                }
            }
            #if os(visionOS)
            .padding(.horizontal, 8)
            #endif
            .padding(.horizontal)
            .padding(.vertical, 4)
            .sheet(item: $showingTrack) {
                vcContainer.deactivateEditMode()
            } content: { track in
                NavigationView {
                    TrackView(track: track, selection: $showingTrack, sheet: true)
                }
                .environmentObject(vcContainer)
                .environmentObject(trackController)
                .environmentObject(groupController)
                .introspect(.viewController, on: .iOS(.v14, .v15, .v16, .v17)) { vc in
                    vc.presentationController?.delegate = vcContainer
                }
            }
            
            Divider()
            
            ScrollViewReader { proxy in
                List {
                    Button("Go to bottom") {
                        proxy.scrollTo(0)
                    }
                    
                    ForEach(0..<365) { dayComplement in
                        DayRow(364 - dayComplement, tracks: tracks, spaces: weekSeparatorSpaces, lines: weekSeparatorLines)
                            .listRowInsets(.init(top: 4, leading: 0, bottom: 4, trailing: 0))
                            #if os(iOS)
                            .padding(.horizontal)
                            #endif
                    }
                }
                .listStyle(PlainListStyle())
                .introspect(.list, on: .iOS(.v14, .v15)) { tableView in
                    tableView.scrollsToTop = false
                }
                .introspect(.list, on: .iOS(.v16, .v17)) { collectionView in
                    collectionView.scrollsToTop = false
                }
                .padding(0)
                .onAppear {
                    proxy.scrollTo(0, anchor: .top)
                }
                .onChange(of: scrollToBottomToggle) { _ in
                    withAnimation {
                        proxy.scrollTo(0, anchor: .top)
                    }
                }
            }
        }
    }
}

//MARK: Preview

struct TicksView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TicksView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environmentObject(TrackController())
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
