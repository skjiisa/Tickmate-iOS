//
//  OnboardingView.swift
//  Tickmate
//
//  Created by Elaine Lyons on 3/18/21.
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
        + "\nYou can also track any other occurances you might want to remember."
    
    @State private var showingPresets = false
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                LogoView()
                    .frame(maxHeight: 180)
                
                Spacer()
                Text(bodyText)
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(1.0)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                #if os(iOS)
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
                #elseif os(visionOS)
                Button("Get started", action: start)
                #endif
                
                // Hidden navigation link that can be triggered programmatically with showingPresets
                NavigationLink(
                    destination: PresetTracksView(onSelect: select)
                        .toolbar {
                            Button("Close") {
                                dismiss()
                            }
                        },
                    isActive: $showingPresets
                ) {
                    EmptyView()
                }
                .frame(height: 0)
                .opacity(0)
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
    
    let colors = [PresetTracks[0].tracks[1].color, PresetTracks[0].tracks[3].color, PresetTracks[0].tracks[7].color]
    
    let ticked = [
        [true, false, true],
        [true, true, false],
        [true, true, false],
        [false, true, true]
    ]
    
    var body: some View {
        VStack {
            ForEach(0..<4) { row in
                HStack {
                    ForEach(0..<3) { column in
                        RoundedRectangle(cornerRadius: 3.0)
                            .aspectRatio(2, contentMode: .fit)
                            .foregroundColor(ticked[row][column] ? colors[column] : Color(.systemFill))
                    }
                }
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingView(showing: .constant(true))
                .previewDevice(PreviewDevice(rawValue: "iPhone 12 Pro Max"))
                .previewDisplayName("iPhone 12 Pro Max")
            
            OnboardingView(showing: .constant(true))
                .previewDevice(PreviewDevice(rawValue: "iPhone SE (2nd generation)"))
                .previewDisplayName("iPhone SE 2")
            
            OnboardingView(showing: .constant(true))
                .previewDevice(PreviewDevice(rawValue: "iPhone SE (1st generation)"))
                .previewDisplayName("iPhone SE")
            
            OnboardingView(showing: .constant(true))
                .previewDevice(PreviewDevice(rawValue: "Apple Vision Pro"))
                .previewDisplayName("Vision Pro")
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(TrackController())
    }
}
