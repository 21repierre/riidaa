//
//  redaaApp.swift
//  redaa
//
//  Created by Pierre on 2025/02/12.
//

import SwiftUI
import SwiftData
import Apollo

@main
struct redaaApp: App {
    
    let CoreController = CoreDataManager.shared
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, CoreController.context)
        }
    }
}
