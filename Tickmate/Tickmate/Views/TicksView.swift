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
    @FetchRequest(
        entity: Track.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Track.index, ascending: true)],
        predicate: NSPredicate(format: "enabled == YES"))
    private var tracks: FetchedResults<Track>
    
    @AppStorage(Defaults.weekSeparatorLines.rawValue) private var weekSeparatorLines: Bool = true
    @AppStorage(Defaults.weekSeparatorSpaces.rawValue) private var weekSeparatorSpaces: Bool = true
    
    @EnvironmentObject private var trackController: TrackController
    
    var scrollToBottomToggle: Bool = false
    
    @StateObject private var vcContainer = ViewControllerContainer()
    
    @State private var showingTrack: Track?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
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
                                Image(systemName: systemImage)
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
                .introspectViewController { vc in
                    print("TicksView sheet")
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
        .navigationBarTitle("Tickmate", displayMode: .inline)
    }
}

//MARK: Day Row

struct DayRow: View {
    
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var trackController: TrackController
    
    let day: Int
    var tracks: FetchedResults<Track>
    var spaces: Bool
    var lines: Bool
    
    init(_ day: Int, tracks: FetchedResults<Track>, spaces: Bool, lines: Bool) {
        self.day = day
        self.tracks = tracks
        self.spaces = spaces
        self.lines = lines
    }
    
    private var backgroud: some View {
        Group {
            if lines && trackController.weekend(day: day) {
                VStack {
                    Spacer()
                    Capsule()
                        .foregroundColor(.gray)
                        .frame(height: 4)
                        .offset(x: 12, y: 0)
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: nil) {
            if spaces && trackController.insets(day: day) == .top {
                Rectangle()
                    .frame(height: 0)
                    .opacity(0)
            }
            HStack {
                trackController.dayLabel(day: day)
                    .frame(width: 80, alignment: .leading)
                ForEach(tracks) { track in
                    TickView(day: day, track: track, tickController: trackController.tickController(for: track))
                }
            }
            if spaces && day > 0 && trackController.insets(day: day) == .bottom {
                Rectangle()
                    // Make up for the height of the separator line if present
                    .frame(height: lines ? 4 : 0)
                    .opacity(0)
            }
        }
        .listRowBackground(backgroud)
        .id(day)
    }
}

//MARK: Tick View

struct TickView: View {
    
    let day: Int
    
    @ObservedObject var track: Track
    @ObservedObject var tickController: TickController
    
    private var color: Color {
        // If the day is ticked, use the track color. Otherwise, use
        // system fill. If the track is reversed, reverse the check.
        (tickController.getTick(for: day)?.count ?? 0 > 0) != track.reversed ? Color(rgb: Int(track.color)) : Color(.systemFill)
    }
    
    private var validDate: Bool {
        !track.reversed || day <= tickController.todayOffset ?? 0
    }
    
    @State private var pressing = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .foregroundColor(color)
            let count = tickController.getTick(for: day)?.count ?? 0
            if count > 1 {
                Text("\(count)")
                    .foregroundColor(track.lightText ? .white : .black)
            }
        }
        .onTapGesture {
            tickController.tick(day: day)
            UISelectionFeedbackGenerator().selectionChanged()
        }
        .onLongPressGesture { pressing in
            guard track.multiple else { return }
            withAnimation(pressing ? .easeInOut(duration: 0.6) : .interactiveSpring()) {
                self.pressing = pressing
            }
        } perform: {
            guard track.multiple else { return }
            if tickController.untick(day: day) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        }
        .scaleEffect(pressing ? 1.1 : 1)
        .opacity(validDate ? 1 : 0)
        .disabled(!validDate)
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
