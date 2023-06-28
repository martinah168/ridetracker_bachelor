//
//  RideTrackerApp.swift
//  RideTracker
//
//  Created by Martina Hinz on 15.04.21.
//

import SwiftUI

@main
struct RideTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistanceManager.shared
    @Environment(\.scenePhase) var scenePhase
    @StateObject var rootViewObject = InfoViewModel()
    @StateObject var locObject = LocationManager()
    init() {
        HealthKitSetupAssistant.authorizeHealthKit { (authorized, error) in
            
            guard authorized else {
                
                let baseMessage = "HealthKit Authorization Failed"
                
                if let error = error {
                    print("\(baseMessage). Reason: \(error.localizedDescription)")
                } else {
                    print(baseMessage)
                }
                
                return
            }
            
            print("HealthKit Successfully Authorized.")
        }
    }
    
   
    
    var body: some Scene {
        WindowGroup {
            InfoView()
                .environmentObject(rootViewObject)
                .environmentObject(locObject)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }.onChange(of: scenePhase) { _ in
            persistenceController.save()
        }
    }
}
