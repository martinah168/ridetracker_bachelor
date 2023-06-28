//
//  UserViewModel.swift
//  RideTracker
//
//  Created by Martina Hinz on 15.07.21.
//

import SwiftUI
import HealthKit

class UserViewModel: ObservableObject {
    @Published var user = User()
    
    func formatWeight(weight: Double) -> String {
        let weightFormatter = MassFormatter()
        weightFormatter.isForPersonMassUse = true
        return weightFormatter.string(fromValue: weight, unit: MassFormatter.Unit.kilogram)
    }
    
    func loadHKProperties() {
        self.loadSexFromHK()
        self.loadWeightFromHK()
        self.loadHeartRateFromHK()
        self.loadAgeFromHK()
    }
    
    private func loadSexFromHK() {
        do {
            let userSex = try HealthKitSetupAssistant.getAgeSexAndBloodType()
            self.user.biologicalSex = userSex
        } catch let error {
            print("error: \(error)")
        }
    }
    
    private func loadAgeFromHK() {
        do {
            let age = try HealthKitSetupAssistant.getAge()
            self.user.age = age
        } catch let error {
            print("error: \(error)")
        }
        
    }
    
    private func loadWeightFromHK() {
        guard let weightSampleType = HKSampleType.quantityType(forIdentifier: .bodyMass) else {
            print("Body Mass Sample Type is no longer available in HealthKit")
            return
        }
        
        HealthKitSetupAssistant.getMostRecentSample(for: weightSampleType) { (sample, error) in
            guard let sample = sample else {
                if let error = error {
                    print("error: \(error)")
                }
                return
            }
            let weightInKilograms = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            self.user.weightInKilograms = weightInKilograms
        }
    }
    
    private func loadHeartRateFromHK() {
        guard let restingHeartRate = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
            return
        }
        
        HealthKitSetupAssistant.getMostRecentSample(for: restingHeartRate) { (sample, error) in
            guard let sample = sample else {
                if let error = error {
                    print("error: \(error)")
                }
                return
            }
            let rHeart = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            self.user.restingHeartRate = rHeart
        }
    }

}
