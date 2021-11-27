//
//  Column.swift
//  Tickmate
//
//  Created by Elaine Lyons on 11/18/21.
//

import SwiftUI

//MARK: Column

struct Column: View {
    
    @ObservedObject var tickController: TickController
    
    var days: Int
    
    @State private var pressing: Int?
    
    var body: some View {
        // For some reason this is MORE laggy with LazyVStack than VStack.
        VStack {
            ForEach(0..<days) { day in
                TickCell(tickController: tickController, day: day)
            }
        }
    }
}

//MARK: TickCell

struct TickCell: View {
    
    static let untickedColor = Color(.systemFill)
    
    @ObservedObject var tickController: TickController
    
    var day: Int
    
    @State private var pressing = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .foregroundColor((tickController.tickCount(for: day) > 0) != tickController.track.reversed ? tickController.color : Self.untickedColor)
            let count = tickController.tickCount(for: day)
            if count > 1 {
                Text("\(count)")
                    .lineLimit(1)
                    .foregroundColor(tickController.lightText ? .white : .black)
            }
        }
        .frame(height: 32)
        .onTapGesture {
            tickController.tick(day: day)
            UISelectionFeedbackGenerator().selectionChanged()
        }
        .if(tickController.track.multiple) { view in
            // Having this .scaleEffect on every cell caused a tiny bit of lag with the
            // large number of Tracks I tested with. This isn't a perfect solution as
            // a user with that many "multiple" tracks would experience the same lag.
            view.scaleEffect(pressing ? 1.1 : 1)
                .onLongPressGesture { pressing in
                    guard tickController.track.multiple else { return }
                    withAnimation(pressing ? .easeInOut(duration: 0.6) : .interactiveSpring()) {
                        self.pressing = pressing
                    }
                } perform: {
                    guard tickController.track.multiple else { return }
                    if tickController.untick(day: day) {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    }
                }
        }
        .if(tickController.track.reversed) { view in
            let validDay = day <= tickController.todayOffset ?? 0
            view.opacity(validDay ? 1 : 0)
                .disabled(!validDay)
        }
    }
}

//MARK: Previews

struct Row_Previews: PreviewProvider {
    static var track: Track = {
        try! PersistenceController.preview.container.viewContext.fetch(Track.fetchRequest())[0]
    }()
    
    static let trackController = TrackController()
    
    static var previews: some View {
        ScrollView {
            Column(tickController: trackController.tickController(for: track), days: 133)
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environmentObject(trackController)
                .padding()
        }
    }
}
