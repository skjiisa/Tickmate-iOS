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
                .mask(
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [.clear, .black, .black, .black, .clear]), startPoint: .leading, endPoint: .trailing))
                        .padding(.horizontal, 50)
                )
                Spacer()
            }
            .onAppear {
                oldPage = page
            }
            .onChange(of: page) { value in
                if value - oldPage > 0 {
                    print("Right")
                    offset = offset + geo.size.width
                } else {
                    print("Left")
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
