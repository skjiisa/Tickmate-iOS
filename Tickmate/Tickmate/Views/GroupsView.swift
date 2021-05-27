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
    
    @AppStorage(Defaults.showAllTracks.rawValue) private var showAllTracks = true
    
    @EnvironmentObject private var trackController: TrackController
    @EnvironmentObject private var groupController: GroupController
    
    @State private var selection: TrackGroup?
    
    private var groups: [TrackGroup] {
        groupController.fetchedResultsController.fetchedObjects ?? []
    }
    
    //MARK: Body
    
    var body: some View {
        Form {
            Section {
                Toggle("All Tracks", isOn: $showAllTracks)
                
                ForEach(groups) { group in
                    NavigationLink(group.displayName, destination: GroupView(group: group), tag: group, selection: $selection)
                }
                .onDelete(perform: delete)
                .onMove(perform: move)
            }
            
            Section {
                Button("Create new group") {
                    let newGroup = TrackGroup(index: Int16(groups.count), context: moc)
                    select(newGroup, delay: 0.25)
                }
                .centered()
            }
        }
        .navigationTitle("Groups")
        .toolbar {
            EditButton()
        }
    }
    
    //MARK: Functions
    
    private func delete(_ indexSet: IndexSet) {
        indexSet.map { groups[$0] }.forEach(moc.delete)
        trackController.scheduleSave()
    }
    
    private func move(_ indices: IndexSet, newOffset: Int) {
        var groupIndices = groups.enumerated().map { $0.offset }
        groupIndices.move(fromOffsets: indices, toOffset: newOffset)
        groupIndices.enumerated().compactMap { offset, element in
            element != offset ? (group: groups[element], newIndex: Int16(offset)) : nil
        }.forEach { $0.index = $1 }
        
        PersistenceController.save(context: moc)
    }
    
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
        .environmentObject(GroupController(preview: true))
    }
}
