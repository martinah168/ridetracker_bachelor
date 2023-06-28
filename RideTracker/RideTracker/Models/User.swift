//
//  User.swift
//  RideTracker
//
//  Created by Martina Hinz on 16.04.21.
//
import SwiftUI
import HealthKit

struct User {
    var bikeType: BikeType = .cityBike
    var bikeWeight: Double = 0.0
    var biologicalSex: HKBiologicalSex?
    var weightInKilograms: Double = 0.0
    var restingHeartRate: Double = 0.0
    var age: Int = 0
    var basalMetablicRate: Int = 2800
    var efficiencyRate: Double = 0.3
    var totalC: Double = 0.0
    
    //resistance coefficient
    var coefficientR: Double {
        switch bikeType {
        case .mountainBike:
            return 0.017
        case .cityBike:
            return 0.012
        case .racingBike:
            return 0.01
        }
    }
    
    //drag coefficient
    var coefficientD: Double {
        switch bikeType {
        case .mountainBike:
            return 0.19
        case .cityBike:
            return 0.17
        case .racingBike:
            return 0.1
        }
    }
}

enum BikeType: String, Equatable, CaseIterable {
    case mountainBike = "Mountain Bike" 
    case cityBike = "City Bike"
    case racingBike = "Road Bike"
    
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

///Resistance Coefficient = https://img.17qq.com/images/kcmmkonglcv.jpeg
