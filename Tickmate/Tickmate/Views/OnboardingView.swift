//
//  OnboardingView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 3/18/21.
//

import SwiftUI
import CoreData

struct OnboardingView: View {
    
    @Environment(\.managedObjectContext) private var moc
    
    @EnvironmentObject private var trackController: TrackController
    
    @Binding var showing: Bool
    
    let bodyText = "Tickmate is a 1-bit journal for keeping track of any daily occurances."
        + " It's great for tracking habits you hope to build or break,"
        + " so you can visualize your progress over time."
    
    @State private var showingPresets = false
    
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
                Button(action: start) {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(height: 64)
                        .overlay(
                            Text("Get started")
                                .foregroundColor(.white)
                                .font(.headline)
                        )
                }
                .padding()
                
                NavigationLink(
                    destination: PresetTracksView(onSelect: select)
                        .toolbar {
                            Button("Close") {
                                dismiss()
                            }
                        },
                    isActive: $showingPresets) {
                    EmptyView()
                }
            }
            .navigationTitle("Tickmate")
            .padding(.bottom)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func start() {
        // Check if this is a new install by checking if there are any Tracks
        if trackController.fetchedResultsController.fetchedObjects?.first != nil {
            // Thera are existing Tracks, so just dismiss.
            dismiss()
        } else {
            // There are no Tracks, so show the presets.
            showingPresets = true
        }
    }
    
    private func select(_ trackRepresentation: TrackRepresentation) {
        trackController.newTrack(from: trackRepresentation, index: 0, context: moc)
        dismiss()
    }
    
    private func dismiss() {
        UserDefaults.standard.setValue(true, forKey: Defaults.onboardingComplete.rawValue)
        showing = false
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
