
import SwiftUI
import CoreData

@main
struct HyperTyperApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            TypingView()
                .frame(minWidth: 800, minHeight: 600)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
