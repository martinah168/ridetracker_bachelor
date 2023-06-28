//
//  CodeSamples.swift
//  RideTracker
//
//  Created by Martina Hinz on 08.07.21.
//
/*
import Combine
import Foundation
import HealthKit
import CoreLocation
import CoreData
import WatchConnectivity


///send notification to watch to start workout
func sendWorkoutNotification(startWorkout: Bool) {
    print(self.watchCommunication.session.isReachable)
    if self.watchCommunication.session.isReachable,
       let data = try? JSONEncoder().encode(startWorkout.description) {
        self.watchCommunication.session.sendMessageData(data, replyHandler: nil) { error in
            print(error.localizedDescription)
            return
        }
    }
}

 /**
  Gets weather data from an API, fetches heart rate samples from HealthKit and calculates calories for ride afterwards
  
  
  - Parameters:
  - urls: URLS to get weather data for every GPS point from the openweathermap API
  - loc: location array with all GPS points from the cycling route
  */
 #warning("TODO: split into 2 Publishers and chain together")
 func getDataAndCalcCalories(urls: [String], loc: [CLLocation], managedObjectContext: NSManagedObjectContext) {
     let heartRateUnit:HKUnit = HKUnit(from: "count/min")
     
     //send all weather requests
     let req = urls.map { _ in
         NetworkService.shared.getWeatherData()
             .mapError { error -> NetworkServiceError in
                 if let error = error as? NetworkServiceError {
                     return error
                 } else {
                     return NetworkServiceError.nonImplemented
                 }
             }
             .eraseToAnyPublisher()
     }
     
     //fetch heartrate from Health Kit
     let hk = HealthKitSetupAssistant.fetchLatestHeartRateSample(startDate: loc.first?.timestamp ?? Date(), endDate: loc.last?.timestamp ?? Date())
         .mapError { error -> Error  in
             return error
         }
         .eraseToAnyPublisher()
     
     let p = Publishers.MergeMany(req)
         .collect()
         .mapError {
             error -> Error  in
             return error
         }
         .eraseToAnyPublisher()
     
     //calculate Calories after receiving weather data and heart rates
     Publishers.Zip(p, hk)
         .sink(receiveCompletion:{ completion in
             if case let .failure(error) = completion {
                 print(error)
             }
         }, receiveValue: { (weather, heartR) in
             DispatchQueue.main.async {
                 self.weatherResultArray = weather
                 
                 for h in heartR {
                     self.heartRates.updateValue(h.quantity.doubleValue(for: heartRateUnit), forKey: h.startDate)
                 }
                 
                 self.calculateCalories(locArrayFirst: loc, managedObjectContext: managedObjectContext )
             }
         })
         .store(in: &cancellables)
 }


 ///save ride to a CSV on the device
 private func createCSV(from recArray:[Dictionary<String, AnyObject>]) {
     var csvString = "\("Timestamp"), \("Latitude"), \("Longitude"), \("Course"), \("Heart Rate"), \("Speed"), \("Slope"),\("Altitude"), \("KiloCalories"), \("Wind Direction"), \("Wind Speed"), \("Pressure"), \("Temperature")\n\n"
     for dct in recArray {
         csvString = csvString.appending("\(String(describing: dct["Timestamp"]!)),\(String(describing: dct["Latitude"]!)),\(String(describing: dct["Longitude"]!)),\(String(describing: dct["Course"]!)),\(String(describing: dct["Heart Rate"]!)),\(String(describing: dct["Speed"]!)),\(String(describing: dct["Slope"]!)),\(String(describing: dct["Altitude"]!)), \(String(describing: dct["KiloCalories"]!)), \(String(describing: dct["Wind Direction"]!)), \(String(describing: dct["Wind Speed"]!)), \(String(describing: dct["Pressure"]!)), \(String(describing: dct["Temperature"]!)) \n")
     }
     
     do {
         let dateFormatter: DateFormatter = DateFormatter()
         dateFormatter.dateFormat = "yyyy_MMM_dd_HH_mm_ss"
         let date = Date()
         let dateString = dateFormatter.string(from: date)
         
         var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
         url.appendPathComponent("CSVLoc_\(dateString)_.csv")
         try csvString.write(to: url, atomically: true, encoding: .utf8)
     } catch {
         print("error creating file")
     }
     
 }
 
 ///save ride to core data
 private func saveRide(distance: Double, duration: Double, calories: Double, locations: [CLLocation], managedObjectContext: NSManagedObjectContext) {
     let newRide = Ride(context: managedObjectContext)
     newRide.distance = distance
     newRide.duration = duration
     newRide.calories = calories
     newRide.timestamp = Date()
     
     for (index,loc) in locations.enumerated() {
         let locationObject = Location(context: managedObjectContext)
         locationObject.timestamp = loc.timestamp
         locationObject.latitude = loc.coordinate.latitude
         locationObject.longitude = loc.coordinate.longitude
         locationObject.speed = loc.speed
         locationObject.windSpeed = weatherResults[index].windSpeed
         locationObject.windDirection = Int64(exactly: weatherResults[index].windDirection) ?? -1
         newRide.addToRideToLocations(locationObject)
     }
     PersistanceManager.shared.save()
 }
 
 private func saveToHK(startDate: Date?, endDate: Date?, locDistance: Double) {
     let totalBurnCal = calories.reduce(0.0,+)
     
     guard let startDate = startDate, let endDate = endDate else {
         return
     }
     
     let calorie = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: totalBurnCal)
     
     let distance = HKQuantity(unit: HKUnit.meter(), doubleValue: locDistance)
     
     let workout = HKWorkout(activityType: .cycling, start: startDate, end: endDate, duration: startDate.distance(to: endDate), totalEnergyBurned: calorie, totalDistance: distance, metadata: nil)
     
     HKHealthStore().save(workout) { (success: Bool, error: Error?) -> Void in
         if success {
             print("workout saved")d
         }
         else {
            print(error.localizeddescription // Workout was not successfully saved
         }
     }
 }
*/
