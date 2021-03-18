//
//  OnboardingView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 3/18/21.
//

import SwiftUI

struct OnboardingView: View {
    
    @Binding var showing: Bool
    
    let bodyText = "Tickmate is a 1-bit journal for keeping track of any daily occurances."
        + " It's great for tracking habits you hope to build or break,"
        + " so you can visualize your progress over time."
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                LogoView()
                    .padding()
                    .scaleEffect()
                
                Spacer()
                Text(bodyText)
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(1.0)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button {
                    showing = false
                } label: {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(height: 64)
                        .padding()
                        .overlay(
                            Text("Get started")
                                .foregroundColor(.white)
                                .font(.headline)
                        )
                }
            }
            .navigationTitle("Tickmate")
            .padding(.bottom)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct LogoView: View {
    
    let colors = [PresetTracks[1].color, PresetTracks[3].color, PresetTracks[7].color]
    
    let ticked = [
        [true, false, true],
        [true, true, false],
        [true, true, false],
        [false, true, true]
    ]
    
    var body: some View {
        VStack {
            ForEach(0..<ticked.count) { row in
                HStack {
                    ForEach(0..<3) { column in
                        RoundedRectangle(cornerRadius: 3.0)
                            .frame(width: 64, height: 32)
                            .foregroundColor(ticked[row][column] ? colors[column] : Color(.systemFill))
                    }
                }
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(showing: .constant(true))
            .previewDevice(PreviewDevice(rawValue: "iPhone 12 Pro Max"))
            .previewDisplayName("iPhone 12 Pro Max")
        
        OnboardingView(showing: .constant(true))
            .previewDevice(PreviewDevice(rawValue: "iPhone SE (1st generation)"))
            .previewDisplayName("iPhone SE")
    }
}
