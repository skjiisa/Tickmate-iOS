//
//  PagingView.swift
//  Tickmate
//
//  Created by Elaine Lyons on 11/18/21.
//

import SwiftUI

struct PagingView: View {
    
    @StateObject private var pagingController = PagingController()
    
    private var title: some View {
        VStack {
            Text("PagedVerticalScroll")
                .font(.title3)
                .offset(x: -pagingController.offset)
            Spacer()
        }
    }
    
    private var bar: some View {
        HStack {
            LazyVStack {
                ForEach(0..<100) { i in
                    Text("\(i)")
                        .padding(4)
                        .frame(height: 44)
                }
            }
            .frame(width: 80)
            .background(Color(.systemBackground)
                            .shadow(radius: pagingController.moving ? 8 : 0))
            // Would need to get an anchor point in the center of the screen to have a scale effect
            //.scaleEffect(pagingController.moving ? 1.05 : 1)
            Spacer()
        }
        .clipped()
    }
    
    var body: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                List {
                    LazyHStack(spacing: 0) {
                        Text("Today")
                            .frame(width: geo.size.width)
                            .border(Color.orange, width: 2)
                        Text("Today")
                            .frame(width: geo.size.width)
                            .border(Color.blue, width: 2)
                        Text("Today")
                            .frame(width: geo.size.width)
                            .border(Color.red, width: 2)
                    }
                }
                .listStyle(.plain)
                .border(Color.green, width: 2)
                .frame(width: geo.size.width * 3, alignment: .leading)
                //.overlay(bar)
            }
            .introspectScrollView { scrollView in
                pagingController.load(scrollView: scrollView)
            }
            //.overlay(title)
        }
        .navigationTitle("PagedVerticalScroll")
    }
}

struct PagingView_Previews: PreviewProvider {
    static var previews: some View {
        PagingView()
    }
}
