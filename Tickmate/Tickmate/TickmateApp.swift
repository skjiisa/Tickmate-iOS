//
//  TickmateApp.swift
//  Tickmate
//
//  Created by Elaine Lyons on 2/19/21.
//

import SwiftUI

@main
struct TickmateApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var trackController = TrackController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(trackController)
        }
    }
}
