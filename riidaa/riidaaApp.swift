//
//  riidaaApp.swift
//  riidaa
//
//  Created by Pierre on 2025/02/12.
//

import SwiftUI
import SwiftData
import Apollo

@main
struct riidaaApp: App {
    
    let CoreController = CoreDataManager.shared
    @StateObject var appManager: AppManager = AppManager.shared
    
    var body: some Scene {
        WindowGroup {
            if appManager.isLoading {
                Text("Loading...")
            } else {
                HomeView()
                    .environment(\.managedObjectContext, CoreController.context)
                    .environmentObject(appManager)
            }
        }
    }
}
