//
//  HydroMinderApp.swift
//  HydroMinder
//
//  Created by Amanda on 4/9/24.
//

import SwiftUI

@main
struct HydroMinderApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
