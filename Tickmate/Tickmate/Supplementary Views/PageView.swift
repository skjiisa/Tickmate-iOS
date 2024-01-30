//
//  PageView.swift
//  Tickmate
//
//  Created by Elaine Lyons on 5/18/21.
//

import SwiftUI

struct PageView<Content: View>: View {
    
    var pageCount: Int
    @Binding var currentIndex: Int
    @ViewBuilder var content: Content
    
    @GestureState private var translation: CGFloat = 0
    @State private var dragging = true
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                content.frame(width: geo.size.width)
            }
            .frame(width: geo.size.width, alignment: .leading)
            .offset(x: offset)
            .gesture(
                DragGesture().updating($translation) { value, state, _ in
                    dragging = true
                    // If TicksView was actually performant, this shouldn't be
                    // needed, but it's actually really laggy. Adding as
                    // minuscule an animation possible magically smoothes it.
                    withAnimation(.easeOut(duration: 0.05)) {
                        updateOffset(geometryReaderWidth: geo.size.width)
                    }
                    state = (currentIndex == 0 && value.translation.width > 0)
                        || (currentIndex == pageCount - 1 && value.translation.width < 0)
                        ? value.translation.width / 3
                        : value.translation.width
                }
                .onEnded { value in
                    let offset = value.predictedEndTranslation.width / geo.size.width
                    let newIndex = Int((CGFloat(currentIndex) - offset).rounded())
                    let adjacentIndex = newIndex > currentIndex
                        ? min(newIndex, currentIndex + 1)
                        : newIndex < currentIndex
                        ? max(newIndex, currentIndex - 1)
                        : currentIndex
                    dragging = false
                    currentIndex = min(max(adjacentIndex, 0), pageCount - 1)
                    withAnimation(.push) {
                        updateOffset(geometryReaderWidth: geo.size.width)
                    }
                }
            )
            .onChange(of: pageCount) { _ in updatePage() }
            .onAppear(perform: updatePage)
        }
    }
    
    private func updateOffset(geometryReaderWidth: CGFloat) {
        offset = -CGFloat(currentIndex) * geometryReaderWidth + translation
    }
    
    private func updatePage() {
        // If scrolled passed the end (such as when
        // a group is removed), go to the last page.
        if currentIndex > pageCount - 1 {
            currentIndex = pageCount - 1
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
