//
//  moooodApp.swift
//  mooood
//
//  Created by Boris Eder on 04.10.25.
//

import SwiftUI
import SwiftData

@main
struct moooodApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: DailyEntry.self)
    }
}
