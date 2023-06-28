//
//  RideTrackerApp.swift
//  WatchRideTracker Extension
//
//  Created by Martina Hinz on 30.05.21.
//

import SwiftUI

@main
struct RideTrackerApp: App {
    
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
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                WatchView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
