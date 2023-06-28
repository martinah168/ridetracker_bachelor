//
//  LocationManager.swift
//  RideTracker
//
//  Created by Martina Hinz on 17.04.21.
//

import SwiftUI
import MapKit
import CoreMotion

//TODO: clean this up

class LocationManager: NSObject, ObservableObject  {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation? = nil
    @Published var oldLocation: CLLocation? = nil
    @Published var locationsArray: [CLLocation] = []
    @Published var distance: Double = 0.0
    
    @Published var speed: CLLocationSpeed? = nil
    
    @Published var city = ""
    @Published var weatherResult: Result? = nil
    private var cntWeather: Int = 0
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.activityType = CLActivityType.fitness
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.delegate = self
    }
    
    func stopLocationTracking() {
        
        self.locationManager.stopUpdatingLocation()
        print("stopped update")
    }
    
    func startTracking() {
        self.locationManager.startUpdatingLocation()
        print("started update")
    }
    
}

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //add new location
        guard let location =  locations.last else {
            //throw MethodError.locationUnrwappingError
            return
        }
        self.location = location
        
        
        //only append newlocations
        if((self.locationsArray.isEmpty) || self.locationsArray.count == 0) {
            self.locationsArray = []
            self.locationsArray.append(location)
        } else {
            //wtf is happenin here with wrapping and unwrapping
            guard let lastLocation = self.locationsArray.last else {
               // throw MethodError.locationSavingError
                return
            }
            if location.distance(from: lastLocation) != 0 {
                
                self.oldLocation = lastLocation
                self.locationsArray.append(location)
                self.distance += abs(self.oldLocation?.distance(from: location) ?? 0.0)
                
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager: \(error)")
    }
}

