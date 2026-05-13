//
//  TickmateApp.swift
//  Tickmate
//
//  Created by Elaine Lyons on 2/19/21.
//

import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

@main
struct TickmateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let persistenceController = PersistenceController.shared
//        .loadDemo() // Uncomment this to load demo data into a fresh install

    @AppStorage(Defaults.useNewUI.rawValue) var useNewUI = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let defaults = UserDefaults.standard
        // If the new UI was active last launch but never reached the active state,
        // it likely crashed — revert to the stable default.
        if defaults.bool(forKey: Defaults.useNewUI.rawValue),
           !defaults.bool(forKey: Defaults.newUILaunchedCleanly.rawValue) {
            defaults.set(false, forKey: Defaults.useNewUI.rawValue)
        }
        defaults.set(false, forKey: Defaults.newUILaunchedCleanly.rawValue)
    }

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
        .onChange(of: scenePhase) { phase in
            if phase == .active, useNewUI {
                UserDefaults.standard.set(true, forKey: Defaults.newUILaunchedCleanly.rawValue)
            }
        }
    }
}
