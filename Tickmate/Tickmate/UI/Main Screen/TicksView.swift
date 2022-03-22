//
//  TicksView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/19/21.
//

import SwiftUI
import SwiftDate
import Introspect

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
            sortDescriptors: [NSSortDescriptor(keyPath: \Track.index, ascending: true)],
            predicate: NSPredicate(format: "enabled == YES"))
    }
    
    init(group: TrackGroup, scrollToBottomToggle: Bool = false) {
        self.scrollToBottomToggle = scrollToBottomToggle
        fetchRequest = FetchRequest(
            entity: Track.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Track.index, ascending: true)],
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
                        UISelectionFeedbackGenerator().selectionChanged()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .foregroundColor(Color(.systemFill))
                                .frame(height: 32)
                            if let systemImage = track.systemImage {
                                Text("\(Image(systemName: systemImage))")
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
            .sheet(item: $showingTrack) {
                vcContainer.deactivateEditMode()
            } content: { track in
                NavigationView {
                    TrackView(track: track, selection: $showingTrack, sheet: true)
                }
                .environmentObject(vcContainer)
                .environmentObject(trackController)
                .environmentObject(groupController)
                .introspectViewController { vc in
                    vc.presentationController?.delegate = vcContainer
                }
            }
            
            Divider()
            
            ScrollViewReader { proxy in
                List {
                    Button("Go to bottom") {
                        proxy.scrollTo(0)
                    }
                    
                    ForEach(0..<TickController.numDays) { dayComplement in
                        DayRow(TickController.numDays - 1 - dayComplement, tracks: tracks, spaces: weekSeparatorSpaces, lines: weekSeparatorLines)
                            .listRowInsets(.init(top: 4, leading: 0, bottom: 4, trailing: 0))
                            .padding(.horizontal)
                    }
                }
                .listStyle(PlainListStyle())
                .introspectTableView { tableView in
                    tableView.scrollsToTop = false
                }
                .padding(0)
                .onAppear {
                    proxy.scrollTo(0)
                }
                .onChange(of: scrollToBottomToggle) { _ in
                    withAnimation {
                        proxy.scrollTo(0)
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
    }
}
