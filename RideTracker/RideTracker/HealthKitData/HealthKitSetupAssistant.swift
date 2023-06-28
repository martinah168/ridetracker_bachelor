//
//  HealthKitSetupAssistant.swift
//  RideTracker
//
//  Created by Martina Hinz on 16.04.21.
//
import Foundation
import HealthKit
import Combine

class HealthKitSetupAssistant {
    let hkStore = HKHealthStore()
    
    private enum HealthkitSetupError: Error {
        case notAvailableOnDevice
        case dataTypeNotAvailable
    }
    
    class func authorizeHealthKit(completion: @escaping (_ success:Bool, _ error:Error?) -> Swift.Void) {
        
        guard HKHealthStore.isHealthDataAvailable() else {
            // Handle when Healthkit is not available
            completion(false, nil)
            return
        }
        
        guard let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass),
              let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
              let biologicalSex = HKObjectType.characteristicType(forIdentifier: .biologicalSex),
              let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate),
              let restingHeartRate = HKObjectType.quantityType(forIdentifier: .restingHeartRate),
              let activeCalories = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(false, HealthkitSetupError.dataTypeNotAvailable)
            return
        }
        
        let healthKitTypesToRead: Set<HKObjectType> = [bodyMass, dateOfBirth, biologicalSex, heartRate, restingHeartRate, HKObjectType.workoutType(), activeCalories]
        let healthKitTypesToWrite: Set<HKSampleType> = [HKObjectType.workoutType()]
        
        HKHealthStore().requestAuthorization(toShare: healthKitTypesToWrite, read: healthKitTypesToRead) { (success, error) in
            
            if let error = error {
                
                // Handle when an error occurred while authorizing
                completion(success,error)
                
            } else {
                
                completion(success,nil)
                
            }
        }
    }
    
    class func fetchLatestHeartRateSample(startDate: Date, endDate: Date) -> AnyPublisher<[HKQuantitySample], Error> {
        /// Create sample type for the heart rate
        guard let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return Fail(error: HealthKitError.cannotComposeUrl).eraseToAnyPublisher()
        }
        
        // Create the subject.
        let subject = PassthroughSubject<[HKQuantitySample], Error>()
        
        /// Predicate for specifiying start and end dates for the query
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictEndDate)
        
        /// Set sorting by date.
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: heartRate, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (_, results, error) in
            guard error == nil else {
                print("Error: \(error!.localizedDescription)")
                subject.send(completion: .failure(error!))
                return
            }
            guard let samples = results as? [HKQuantitySample] else {
                subject.send(completion: .finished)
                return
            }
            
            subject.send(samples)
            subject.send(completion: .finished)
        }
        
        /// Execute the query in the health store
        let healthStore = HKHealthStore()
        healthStore.execute(query)
        return subject.eraseToAnyPublisher()
    }
    
    class func getAgeSexAndBloodType() throws -> HKBiologicalSex  {
        
        let healthKitStore = HKHealthStore()
        
        do {
            let biologicalSex =       try healthKitStore.biologicalSex()
            
            //3. Unwrap the wrappers to get the underlying enum values.
            let unwrappedBiologicalSex = biologicalSex.biologicalSex
            
            return unwrappedBiologicalSex
        }
    }
    
    class func getAge() throws -> Int {
        let healthKitStore = HKHealthStore()
        let birthdayComponents =  try healthKitStore.dateOfBirthComponents()
        
        let today = Date()
        let calendar = Calendar.current
        let todayDateComponents = calendar.dateComponents([.year],
                                                          from: today)
        let thisYear = todayDateComponents.year!
        let age = thisYear - birthdayComponents.year!
        
        return age
    }
    
    class func getMostRecentSample(for sampleType: HKSampleType,
                                   completion: @escaping (HKQuantitySample?, Error?) -> Swift.Void) {
        
        //1. Use HKQuery to load the most recent samples.
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast,
                                                              end: Date(),
                                                              options: .strictEndDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                              ascending: false)
        
        let limit = 1
        
        let sampleQuery = HKSampleQuery(sampleType: sampleType,
                                        predicate: mostRecentPredicate,
                                        limit: limit,
                                        sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            
            //2. Always dispatch to the main thread when complete.
            DispatchQueue.main.async {
                
                guard let samples = samples,
                      let mostRecentSample = samples.first as? HKQuantitySample else {
                    
                    completion(nil, error)
                    return
                }
                
                completion(mostRecentSample, nil)
            }
        }
        
        HKHealthStore().execute(sampleQuery)
    }
}


enum HealthKitError: Error {
    
    case nonImplemented
    case cannotComposeUrl
    
    var description: String {
        switch self {
        case .nonImplemented:
            return "Function not implemented"
        case .cannotComposeUrl:
            return "Cannot compose URL"
        }
    }
}
