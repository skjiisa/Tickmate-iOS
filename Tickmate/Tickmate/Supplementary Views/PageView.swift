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
    @Binding var offset: CGFloat
    @ViewBuilder var content: Content
    
    @GestureState private var translation: CGFloat = 0
    @State private var dragging = true
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                content.frame(width: geo.size.width)
            }
            .frame(width: geo.size.width, alignment: .leading)
            .offset(x: -CGFloat(currentIndex) * geo.size.width + translation)
            .animation(dragging ? .none : .push)
            .gesture(
                DragGesture().updating($translation) { value, state, _ in
                    dragging = true
                    let width = (currentIndex == 0 && value.translation.width > 0)
                        || (currentIndex == pageCount - 1 && value.translation.width < 0)
                        ? value.translation.width / 3
                        : value.translation.width
                    state = width
                    offset = width
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
                    let oldIndex = currentIndex
                    currentIndex = min(max(adjacentIndex, 0), pageCount - 1)
                    if oldIndex == currentIndex {
                        withAnimation(.push) {
                            self.offset = 0
                        }
                    }
                }
            )
            .onChange(of: pageCount) { _ in updatePage() }
            .onAppear(perform: updatePage)
        }
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
        PageView(pageCount: 2, currentIndex: .constant(0), offset: .constant(0)) {
            Text("One")
            Text("Two")
        }
    }
}
