//
//  TickmateApp.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/19/21.
//

import SwiftUI

@main
struct TickmateApp: App {
    let persistenceController = PersistenceController.shared
    
    let newUI = false

    var body: some Scene {
        WindowGroup {
            if newUI {
                NewUI()
            } else {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
