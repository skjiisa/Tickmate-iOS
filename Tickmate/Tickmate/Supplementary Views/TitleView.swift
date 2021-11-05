//
//  TitleView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 7/9/21.
//

import SwiftUI

struct TitleView: View {
    
    @Binding var offset: CGFloat
    @Binding var page: Int
    var titles: [String]
    
    @State private var oldPage = 0
    
    private var mask: some View {
        Rectangle().fill(LinearGradient(gradient: Gradient(colors: [.clear, .black, .black, .black, .clear]), startPoint: .leading, endPoint: .trailing))
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                ZStack {
                    HStack {
                        Spacer()
                        Text(title(for: page - 1))
                            .fontWeight(.semibold)
                            .offset(x: offset - geo.size.width)
                        Spacer()
                    }
                    
                    HStack {
                        Spacer()
                        Text(title(for: page))
                            .fontWeight(.semibold)
                            .offset(x: offset)
                        Spacer()
                    }
                    
                    HStack {
                        Spacer()
                        Text(title(for: page + 1))
                            .fontWeight(.semibold)
                            .offset(x: offset + geo.size.width)
                        Spacer()
                    }
                }
                .font(.title3)
                .padding(.top, 10)
                .mask(mask)
                // Uncomment the below line to visualize the mask
                //.overlay(mask.border(Color.red, width: 2))
                Spacer()
            }
            .padding(.horizontal, 50)
            .onAppear {
                oldPage = page
            }
            .onChange(of: page) { value in
                if value - oldPage > 0 {
                    offset = offset + geo.size.width
                } else {
                    offset = offset - geo.size.width
                }
                withAnimation(.push) {
                    offset = 0
                }
                oldPage = page
            }
        }
    }
    
    private func title(for index: Int) -> String {
        guard titles.indices.contains(index) else { return "" }
        return titles[index]
    }
}
