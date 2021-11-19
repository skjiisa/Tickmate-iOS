//
//  TracksPage.swift
//  Tickmate
//
//  Created by Elaine Lyons on 11/18/21.
//

import SwiftUI

struct TracksPage: View {
    
    @EnvironmentObject private var trackController: TrackController
    
    var days: Int
    
    private var fetchRequest: FetchRequest<Track>
    private var tracks: FetchedResults<Track> {
        fetchRequest.wrappedValue
    }
    
    init(days: Int) {
        self.days = days
        fetchRequest = FetchRequest(
            entity: Track.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Track.index, ascending: true)],
            predicate: NSPredicate(format: "enabled == YES"))
    }
    
    init(group: TrackGroup, days: Int) {
        self.days = days
        fetchRequest = FetchRequest(
            entity: Track.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Track.index, ascending: true)],
            predicate: NSPredicate(format: "enabled == YES AND %@ IN groups", group))
    }
    
    init(fetchRequest: FetchRequest<Track>, days: Int) {
        self.days = days
        self.fetchRequest = fetchRequest
    }
    
    var body: some View {
        HStack {
            ForEach(tracks) { track in
                Column(tickController: trackController.tickController(for: track), days: days)
            }
        }
    }
}

struct TracksPage_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            TracksPage(days: 133)
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environmentObject(TrackController())
                .padding()
        }
    }
}
