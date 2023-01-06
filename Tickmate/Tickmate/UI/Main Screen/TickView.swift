//
//  TickView.swift
//  Tickmate
//
//  Created by Elaine Lyons on 6/24/21.
//

import SwiftUI

//MARK: - Day Row

struct DayRow<C: RandomAccessCollection>: View where C.Element == Track {
    
    @EnvironmentObject private var trackController: TrackController
    
    let day: Int
    var tracks: C
    var spaces: Bool
    var lines: Bool
    var widget: Bool
    var compact: Bool
    var showDate: Bool
    
    init(_ day: Int, tracks: C, spaces: Bool, lines: Bool, widget: Bool = false, compact: Bool = false, showDate: Bool = true) {
        self.day = day
        self.tracks = tracks
        self.spaces = spaces
        self.lines = lines
        self.widget = widget
        self.compact = compact
        self.showDate = showDate
    }
    
    @ViewBuilder
    private var background: some View {
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: nil) {
            if spaces && trackController.insets(day: day) == .top {
                Rectangle()
                    .frame(height: 0)
                    .opacity(0)
            }
            HStack(spacing: 4) {
                Group {
                    if showDate {
                        let label = trackController.dayLabel(day: day, compact: widget)
                        TextWithCaption(label.text, caption: widget ? nil : label.caption)
                            .lineLimit(1)
                            .font(compact ? .system(size: 11) : .body)
                    } else {
                        Color.clear
                    }
                }
                .frame(width: compact ? 30 : widget ? 50 : 80, alignment: .leading)
                
                ForEach(tracks) { track in
                    TickView(day: day, widget: widget, compact: compact, track: track, tickController: trackController.tickController(for: track))
                }
            }
            if spaces && trackController.insets(day: day) == .bottom {
                Rectangle()
                    // Make up for the height of the separator line if present
                    .frame(height: lines ? 4 : 0)
                    .opacity(0)
            }
        }
        .listRowBackground(background)
        .id(day)
    }
}

//MARK: - Tick View

struct TickView: View {
    
    let day: Int
    var widget: Bool
    var compact: Bool
    
    @ObservedObject var track: Track
    @ObservedObject var tickController: TickController
    
    private var color: Color {
        // If the day is ticked, use the track color. Otherwise, use
        // system fill. If the track is reversed, reverse the check.
        (tickController.tickCount(for: day) > 0) != track.reversed ? Color(rgb: Int(track.color)) : Color(.systemFill)
    }
    
    private var validDate: Bool {
        !track.reversed || day <= tickController.todayOffset ?? 0
    }
    
    @State private var pressing = false
    
    var body: some View {
        ZStack {
            if widget {
                RoundedRectangle(cornerRadius: 3)
                    .foregroundColor(color)
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .foregroundColor(color)
                    .frame(height: 32)
            }
            let count = tickController.tickCount(for: day)
            if count > 1 {
                Text("\(count)")
                    .lineLimit(1)
                    .foregroundColor(track.lightText ? .white : .black)
                    .font(compact ? .system(size: 11) : .body)
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

/*
struct TickView_Previews: PreviewProvider {
    static var previews: some View {
        DayRow()
    }
}
*/
