//
//  HKBiologicalSex+StringExtension.swift
//  RideTracker
//
//  Created by Martina Hinz on 16.04.21.
//

import HealthKit

extension HKBiologicalSex {
  
  var stringRepresentation: String {
    switch self {
    case .notSet: return "Unknown"
    case .female: return "Female"
    case .male: return "Male"
    case .other: return "Other"
    }
  }
}
