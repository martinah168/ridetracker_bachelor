//
//  WorkoutHelper.swift
//  WatchRideTracker Extension
//
//  Created by Martina Hinz on 30.05.21.
//

import Foundation
import WatchConnectivity

class ViewModelWatch: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = ViewModelWatch()
    var session: WCSession
    @Published var startedWorkout = false
    
    init(session: WCSession = .default){
        self.session = session
        super.init()
        self.session.delegate = self
        session.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        guard let bool = try? JSONDecoder().decode(String.self, from: messageData) else {
            print("error couldnt encode data")
            return
        }
        let start = bool != "false"
        if start {
            DispatchQueue.main.async {
                self.startedWorkout = true
            }
        } else {
            DispatchQueue.main.async {
                self.startedWorkout = false
            }
        }
    }
}

