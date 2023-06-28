//
//  WorkoutModel.swift
//  WatchRideTracker Extension
//
//  Created by Martina Hinz on 31.05.21.
//

import Foundation
import HealthKit


class WorkoutModel: NSObject, ObservableObject {
    
    var session: HKWorkoutSession!
    var builder: HKLiveWorkoutBuilder!
    @Published var heartRate: Double = 0
    @Published var calories: Double = 0
    
    func startWorkoutWithHealthStore() {
        let healthStore = HKHealthStore()
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .cycling
        configuration.locationType = .outdoor
    
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session.associatedWorkoutBuilder()
        } catch {
            #warning("TODO: handle failure")
            return
        }
        
        session.delegate = self
        builder.delegate = self
        
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                     workoutConfiguration: configuration)
        session.startActivity(with: Date())
        builder.beginCollection(withStart: Date()) { _, error in
            if let error = error {
                print(error)
            }
        }
    }
    
    func endWorkout() {
        session.end()
    }
    
    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else {
            return
        }
        
        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                guard let value = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) else {
                    return
                }
                let roundedValue = Double(round(1 * value) / 1)
                self.heartRate = roundedValue
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let energyUnit = HKUnit.kilocalorie()
                self.calories = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
            default:
                return
            }
        }
    }
}

extension WorkoutModel: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        if toState == .ended {
            builder.endCollection(withEnd: Date()) { _, error in
                self.builder.finishWorkout { _, error in
                    if let error = error {
                        print("error: \(error)")
                    }
                    
                    self.session = nil
                }
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) { }
}

extension WorkoutModel: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return
            }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            updateForStatistics(statistics)
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }
}


