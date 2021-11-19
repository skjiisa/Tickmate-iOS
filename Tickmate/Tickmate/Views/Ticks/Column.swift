//
//  Column.swift
//  Tickmate
//
//  Created by Elaine Lyons on 11/18/21.
//

import SwiftUI

struct Column: View {
    @ObservedObject var tickController: TickController
    
    var days: Int
    
    static let untickedColor = Color(.systemFill)
    
    var body: some View {
        // For some reason this is MORE laggy with LazyVStack than VStack.
        VStack {
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
