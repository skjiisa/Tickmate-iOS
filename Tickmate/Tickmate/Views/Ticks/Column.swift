//
//  Column.swift
//  Tickmate
//
//  Created by Isaac Lyons on 11/18/21.
//

import SwiftUI

struct Column: View {
    @ObservedObject var tickController: TickController
    
    private let days = 100
    
    static let untickedColor = Color(.systemFill)
    
    var body: some View {
        LazyVStack(spacing: 20) {
            ForEach(0..<days) { day in
                RoundedRectangle(cornerRadius: 3)
                    .foregroundColor((tickController.tickCount(for: day) > 0) != tickController.track.reversed ? tickController.color : Self.untickedColor)
                    .frame(height: 32)
            }
        }
    }
}

/*
struct Row_Previews: PreviewProvider {
    static var previews: some View {
        Column()
    }
}
 */
