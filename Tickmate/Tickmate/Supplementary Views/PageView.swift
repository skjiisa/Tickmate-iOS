//
//  PageView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 5/18/21.
//

import SwiftUI

struct PageView<Content: View>: View {
    
    var pageCount: Int
    @Binding var currentIndex: Int
    @ViewBuilder var content: Content
    
    @GestureState private var translation: CGFloat = 0
    @State private var dragging = false
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                content.frame(width: geo.size.width)
            }
            .frame(width: geo.size.width, alignment: .leading)
            .offset(x: -CGFloat(currentIndex) * geo.size.width + translation)
            // Might want to figure out a better animation to use here
            .animation(dragging ? .none : .spring())
            .gesture(
                DragGesture().updating($translation) { value, state, _ in
                    dragging = true
                    state = (currentIndex == 0 && value.translation.width > 0)
                        || (currentIndex == pageCount - 1 && value.translation.width < 0)
                        // This could be more advanced than just / 2
                        ? value.translation.width / 2
                        : value.translation.width
                }
                .onEnded { value in
                    let offset = value.translation.width / geo.size.width
                    let newIndex = (CGFloat(currentIndex) - offset).rounded()
                    dragging = false
                    currentIndex = min(max(Int(newIndex), 0), pageCount - 1)
                }
            )
            .onChange(of: pageCount) { value in
                if currentIndex > value - 1 {
                    currentIndex = value - 1
                }
            }
        }
    }
}

struct PageView_Previews: PreviewProvider {
    static var previews: some View {
        PageView(pageCount: 2, currentIndex: .constant(0)) {
            Text("One")
            Text("Two")
        }
    }
}
