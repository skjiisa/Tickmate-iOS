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
        .loadDemo() // Uncomment this to load demo data into a fresh install
    
    @AppStorage(Defaults.useNewUI.rawValue) var useNewUI = false

    var body: some Scene {
        WindowGroup {
            if useNewUI {
                NewUI()
                    .edgesIgnoringSafeArea(.bottom)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
