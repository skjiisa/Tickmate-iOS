//
//  TickmateApp.swift
//  Tickmate
//
//  Created by Elaine Lyons on 2/19/21.
//

import SwiftUI

@main
struct TickmateApp: App {
    let persistenceController = PersistenceController.shared.loadDemo()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
