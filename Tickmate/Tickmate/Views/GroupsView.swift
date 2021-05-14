//
//  GroupsView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 5/14/21.
//

import SwiftUI

struct GroupsView: View {
    @FetchRequest(entity: TrackGroup.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \TrackGroup.name, ascending: true)])
    private var groups: FetchedResults<TrackGroup>
    
    var body: some View {
        Form {
            ForEach(groups) { group in
                Text(group.name ?? "New Group")
            }
        }
        .navigationTitle("Groups")
    }
}

struct GroupsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GroupsView()
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
