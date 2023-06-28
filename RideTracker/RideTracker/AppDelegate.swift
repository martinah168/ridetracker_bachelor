//
//  AppDelegate.swift
//  RideTracker
//
//  Created by Martina Hinz on 08.05.21.
//

import UIKit
import HealthKit

class AppDelegate: NSObject, UIApplicationDelegate {
    //https://developer.apple.com/forums/thread/667835
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        print("memory warning")
    }
    
    func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
        let healthstore = HKHealthStore()
        healthstore.handleAuthorizationForExtension { (success, error) -> Void in
        
        }
    }
}
