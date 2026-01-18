//
//  HyperTyperApp.swift
//  HyperTyper
//
//  Created by Mariusz Murawski on 18/01/2026.
//

import SwiftUI
import CoreData

@main
struct HyperTyperApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
