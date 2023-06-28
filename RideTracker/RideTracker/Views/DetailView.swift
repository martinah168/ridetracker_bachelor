//
//  WeatherView.swift
//  RideTracker
//
//  Created by Martina Hinz on 19.04.21.
//

import SwiftUI
import MapKit

struct DetailView: View {
    var locationsArray: [Location]
    var region: MKCoordinateRegion
    var calories: Double
    var date: Date
    var heartRates: [Double]
    
    var body: some View {
        VStack {
            List {
                let d = String(format: "Distance: %.01fkm", distance()/1000.0)
                Text("\(d)")
                Text("Duration: \(duration())")
              //  Text(locationsArray.last?.timestamp?.description ?? "")
                Text("Calories: \(String(format: "%.2f",calories)) kcal")
              /*  Text("Average Heartrate: \(String(format: "%.2f", averageHeartRate())) count/min")*/
                Text("Average speed: \(String(format: "%.2f", averageSpeed())) km/h")
                Text("Average Windspeed: \(String(format: "%.2f", averageWindSpeed())) km/h")
               // Text("Average Winddirection: \(averageWindDirection())")
            }.scaledToFit()
            MapView(locationArray: locationsArray, region: region).scaledToFill()
        }.navigationTitle("Ride on the \(dateToString())")
    }
    
    
    #warning("TODO: Move this to a ViewModel")
    func distance() -> Double {
        var distance = 0.0
        for (idx,l) in locationsArray.enumerated() {
            if(idx < locationsArray.count-1) {
                let location1 = CLLocation(latitude: l.latitude, longitude: l.longitude)
                let location2 = CLLocation(latitude: locationsArray[idx+1].latitude, longitude: locationsArray[idx+1].longitude)
                distance += abs(location1.distance(from: location2))
            }
        }
        
        return distance
    }
    
    func averageWindSpeed() -> Double {
//        let test = locationsArray.reduce((0.0, 0.0)) { result, location in
//            (result.0 + location.windSpeed, result.1 + location.speed)
//        }
        let speed = locationsArray.map{$0.windSpeed}.reduce(0.0,+)
        return (speed/Double(locationsArray.count))*3.6
    }
    
    func averageWindDirection() -> Int {
        let direction = locationsArray.map{$0.windDirection}.reduce(0,+)
        return (Int(exactly: direction) ?? -1/locationsArray.count)
    }
    
    func averageHeartRate() -> Double {
        return heartRates.reduce(0.0,+)/Double(heartRates.count)
    }
    
    func duration() -> String {
        let duration = locationsArray.first?.timestamp?.distance(to: locationsArray.last?.timestamp ?? Date()) ?? TimeInterval(0)
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        
        let formattedString = formatter.string(from: TimeInterval(duration))!
        return formattedString
    }
    
    func dateToString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let formattedString = formatter.string(for: date) ?? ""
        return formattedString
    }
    
    func averageSpeed() -> Double {
        let speed = locationsArray.map{$0.speed}.reduce(0.0,+)
        return (speed/Double(locationsArray.count))*3.6
    }
}
