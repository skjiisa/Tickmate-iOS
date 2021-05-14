//
//  GroupsView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 5/14/21.
//

import SwiftUI

struct GroupsView: View {
    
    //MARK: Properties
    
    @Environment(\.managedObjectContext) private var moc
    
    @FetchRequest(
        entity: TrackGroup.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TrackGroup.name, ascending: true)],
        animation: .default)
    private var groups: FetchedResults<TrackGroup>
    
    @AppStorage(Defaults.showAllTracks.rawValue) private var showAllTracks = true
    
    @State private var selection: TrackGroup?
    
    //MARK: Body
    
    var body: some View {
        Form {
            Section {
                Toggle("All Tracks", isOn: $showAllTracks)
                
                ForEach(groups) { group in
                    NavigationLink(group.displayName, destination: GroupView(group: group), tag: group, selection: $selection)
                }
                .onDelete { indexSet in
                    indexSet.map { groups[$0] }.forEach(moc.delete)
                    PersistenceController.save(context: moc)
                }
            }
            
            Section {
                Button("Create new group") {
                    let newGroup = TrackGroup(context: moc)
                    select(newGroup, delay: 0.25)
                }
                .centered()
            }
        }
        .navigationTitle("Groups")
    }
    
    //MARK: Functions
    
    private func select(_ group: TrackGroup, delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            selection = group
        }
    }
}

//MARK: Previews

struct GroupsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GroupsView()
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
