//
//  ContentView.swift
//  RideTracker
//
//  Created by Martina Hinz on 15.04.21.
//

import SwiftUI
import HealthKit
import MapKit
import Combine
import CoreData

//TODO: Use UserDefaults:
/*https://stackoverflow.com/questions/60210824/changing-state-variable-to-value-from-userdefaults-on-load-not-updating-picker*/

//TODO: additionalweight field
struct InfoView: View {
    
    @EnvironmentObject var infoViewModel: InfoViewModel// = InfoViewModel()
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @EnvironmentObject private var locationManager: LocationManager// = LocationManager()
    @StateObject var user = UserViewModel()
    
    
    @FetchRequest(entity: Ride.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Ride.timestamp, ascending: false)]) var rides: FetchedResults<Ride>
    
    
    @State var trackingOn = false
    @State var saveable = false
    @State var coordinate = CLLocationCoordinate2D()
    @State var savingLabel = "Save"
    
    @State var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 25.7617, longitude: 80.1918), span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5))
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    
    @State var weatherResults: [Result] = []
    
    
    @State private var selectedItem: String?
    @State private var listViewId = UUID()
    @State var weather = false
    
    //Error handling
    @State var hrErrorValue = ""
    @State var methodErrorValue = ""
    @State var weatherErrorValue = ""
 //   @State var fileState: FileState = .nothingSaved
  //  @State var loading = false
    @State var cancellables = Set<AnyCancellable>()
    
    var userPath: [CLLocationCoordinate2D]? {
//        if let userLocations = self.locationManager.locationsArray {
            return self.locationManager.locationsArray.map( { $0.coordinate })
//        }
//        return nil
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if self.infoViewModel.loading {
                    ProgressView().scaleEffect(x: 2, y: 2, anchor: .center)
                }
                Spacer()
                if self.trackingOn {
                    let d = String(format: " %.02f", self.locationManager.distance/1000.0)
                    HStack {
                        Text("Dist:").font(.system(size: 20)).padding(.top)
                        Text("\(d)")
                            .bold()
                            .font(.system(size: 80))
                        VStack {
                            Text("km").bold().padding(.top).font(.system(size: 20))
                        }
                        
                    }
                  /* Text("\(d)")
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(lineWidth: 2)
                        )
                        .zIndex(1.0)*/
                    /*Text("current location: \(coordinate.latitude), \(coordinate.longitude)")
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(lineWidth: 2)
                        )
                        .zIndex(1.0)*/
                }
                
                
                Button("Start Tracking") {
                    self.saveable = false
                    self.locationManager.distance = 0
                    self.infoViewModel.urls.removeAll()
                    self.locationManager.locationsArray.removeAll()
                    self.infoViewModel.calories.removeAll()
                    self.infoViewModel.heartRates.removeAll()
                    self.infoViewModel.slopes.removeAll()
                    self.infoViewModel.idxWeather.removeAll()
                    self.infoViewModel.methodErrorValue = ""
                    self.infoViewModel.hrErrorValue = ""
                    self.infoViewModel.weatherErrorValue = ""
                    
                    self.trackingOn = true
                    self.locationManager.startTracking()
                    self.infoViewModel.sendWorkoutNotification(startWorkout: trackingOn)
                    
                    
                    let coordinate = self.locationManager.location != nil ? self.locationManager.location!.coordinate : CLLocationCoordinate2D()
                    region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5))
                }
                .disabled(self.trackingOn)
                .foregroundColor(.white)
                .padding()
                .background (self.trackingOn ? Color.gray : Color.blue)
                .cornerRadius(8)
                .zIndex(2.0)
                
                
                Button("Stop Tracking") {
                    self.trackingOn = false
                    self.saveable = true
                    self.locationManager.stopLocationTracking()
                    self.infoViewModel.sendWorkoutNotification(startWorkout: trackingOn)
                    self.infoViewModel.fileState = .nothingSaved
                    self.infoViewModel.methodErrorValue = ""
                    self.infoViewModel.hrErrorValue = ""
                    self.infoViewModel.weatherErrorValue = ""
                    /*self.saveHrData()
                     if self.infoViewModel.hrErrorValue.isEmpty {
                     self.infoViewModel.fileState = .hrSaved
                     }
                     else {
                     self.infoViewModel.fileState = .wait4Hr
                     }*/
                }
                .disabled(!self.trackingOn)
                .foregroundColor(.white)
                .padding()
                .background(!self.trackingOn ? Color.gray : Color.blue)
                .cornerRadius(8)
                .zIndex(3.0)
                
                Button(savingLabel) {
                    switch self.infoViewModel.fileState {
                    case .nothingSaved:
                        print("nothingSaved")
                        self.infoViewModel.loading = true
                        self.infoViewModel.methodErrorValue = ""
                        self.infoViewModel.hrErrorValue = ""
                        self.infoViewModel.weatherErrorValue = ""
                        
                        print(self.user.user.weightInKilograms)
                        
                        DispatchQueue.global(qos: .background).async {
                        self.infoViewModel.saveHrData(loc: self.locationManager.locationsArray, managedObjectContext: self.managedObjectContext, user: self.user.user)
                            DispatchQueue.main.async {
                                self.saveable = false
                            }
                        }
                        //Publishers.Zip(self.infoViewModel.getWeatherData(urls: []), self.infoViewModel.getHrData(loc: []))*/
                       /* guard let loc = self.locationManager.locationsArray else {
                            return
                        }
                        
                        self.infoViewModel.getData(urls: self.infoViewModel.urls, loc: self.locationManager.locationsArray ?? [], managedObjectContext: managedObjectContext, user: self.user.user)*/
                    case .hrSaved:
                        print("hrSaved")
                        self.infoViewModel.loading = true
                        self.infoViewModel.methodErrorValue = ""
                        self.infoViewModel.hrErrorValue = ""
                        self.infoViewModel.weatherErrorValue = ""
                        DispatchQueue.global(qos: .background).async {
                            self.infoViewModel.saveWeatherData(loc: self.locationManager.locationsArray, managedObjectContext: self.managedObjectContext, user: self.user.user)
                        }
                    case .everythingSaved:
                        self.infoViewModel.loading = true
                        
                            self.saveable = true
                        
                        var calc:[Double] = []
                        self.infoViewModel.methodErrorValue = ""
                        self.infoViewModel.hrErrorValue = ""
                        self.infoViewModel.weatherErrorValue = ""
                        DispatchQueue.global(qos: .background).async {
                            do {
                                calc = try self.infoViewModel.calculateCalories(locArrayFirst: self.locationManager.locationsArray ,weatherRes: self.infoViewModel.weatherResultArray, managedObjectContext: managedObjectContext, heartRates: self.infoViewModel.heartRates, user: user.user)
                            } catch let error as MethodError {
                                self.methodErrorValue = error.description
                            } catch  {
                                self.methodErrorValue = error.localizedDescription
                            }
                            DispatchQueue.main.async {
                                self.infoViewModel.calories = calc
                                self.infoViewModel.loading = false
                                
                            }
                        }
                        print("saving done & calculated calories")
                        self.saveable = false
                    case .wait4Hr:
                        print("wait4Hr")
                        self.infoViewModel.loading = true
                        self.infoViewModel.methodErrorValue = ""
                        self.infoViewModel.hrErrorValue = ""
                        self.infoViewModel.weatherErrorValue = ""
                        DispatchQueue.global(qos: .background).async {
                        self.infoViewModel.saveHrData(loc: self.locationManager.locationsArray, managedObjectContext: self.managedObjectContext, user: self.user.user)
                        }
                    case .wait4Weather:
                        print("wait4weather")
                        self.saveable = true
                        self.infoViewModel.loading = true
                        self.infoViewModel.methodErrorValue = ""
                        self.infoViewModel.hrErrorValue = ""
                        self.infoViewModel.weatherErrorValue = ""
                        DispatchQueue.global(qos: .background).async {
                        self.infoViewModel.saveWeatherData(loc: self.locationManager.locationsArray, managedObjectContext: self.managedObjectContext, user: self.user.user)
                            
                        }
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(!self.saveable || self.infoViewModel.fileState == .everythingSaved ? Color.gray : Color.red)
                .cornerRadius(8)
                .zIndex(3.0)
                
                if !self.infoViewModel.methodErrorValue.isEmpty {
                    Text("Method Error: \(self.infoViewModel.methodErrorValue)").foregroundColor(.red)
                }
                if !self.infoViewModel.hrErrorValue.isEmpty {
                    Text("HR Error: \(self.infoViewModel.hrErrorValue)").foregroundColor(.red)
                }
                if !self.infoViewModel.weatherErrorValue.isEmpty {
                    Text("Weather Error: \(self.infoViewModel.weatherErrorValue)").foregroundColor(.red)
                }
                
                Form {
                    Section(header: Text("Saved rides")) {
                        ForEach(rides, id: \.self) { ride in
                            #warning("as?")
                            let loc: [Location] = ride.rideToLocations?.array as? [Location] ?? []
                           /* guard let ride2Loc = ride.rideToLocations else {
                                Text("Coredata error")
                            }
                            guard let loc = ride2Loc.array as? [Location] else {
                               Text("Corelocation from coredata error")
                            }*/
                            
                            let r = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: loc.first?.latitude ?? 30.07, longitude: loc.first?.longitude ?? 14), span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
                                    NavigationLink(
                                        destination: DetailView(locationsArray: loc, region: r, calories: ride.calories, date: ride.timestamp ?? Date(), heartRates: self.infoViewModel.heartRates.compactMap{$0.value})) {
                                        Text("\(dateToString(date: ride.timestamp ?? Date()))")
                                
                            }
                        }
                    }
                }.padding(.top)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Text("")
                        NavigationLink(destination: UserView()) {
                            Image(systemName: "person.circle")
                                .font(.title)
                        }
                    }
                }
            }
        }
        .environmentObject(user)
    }
    
    func dateToString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let formattedString = formatter.string(for: date) ?? ""
        return formattedString
    }
    
//    func filterLocationsForWeather() -> [String] {
//        guard let locArray = self.locationManager.locationsArray else {
//            print("error locationArray empty")
//            return []
//        }
//        var urlArray: [String] = []
//        var startDate = locArray.first?.timestamp ?? Date()
//        var startDistance = 0.0
//        var startLocation = locArray.first
//
//        for (index,loc) in locArray.enumerated() {
//            if startDate.distance(to: loc.timestamp) > TimeInterval(3600) || startDistance > 5000.0 || index == 0 {
//                startDate = loc.timestamp
//                startDistance = 0.0
//                startLocation = loc
//                NetworkService.shared.setLatitude(loc.coordinate.latitude)
//                NetworkService.shared.setLongitude(loc.coordinate.longitude)
//                NetworkService.shared.setDate(loc.timestamp)
//                let url = NetworkService.shared.buildURL()
//                urlArray.append(url)
//            }
//            startDistance += abs(startLocation?.distance(from: loc) ?? 0.0)
//        }
//        return urlArray
//    }
    
    //TODO: die bodenbeschaffenheit https://openrouteservice.org nutzen
    ///default value air density = 1.2
    ///default value wind direction = 370
    ///default value wind speed = 3.0
 /*   func calculateCalories() throws {
        try self.infoViewModel.calculateCalories(locArrayFirst: self.locationManager.locationsArray ,weatherRes: self.infoViewModel.weatherResultArray, managedObjectContext: managedObjectContext, heartRates: self.infoViewModel.heartRates, user: user.user)
        
    }
    
    func saveHrData() {
        do {
            try self.infoViewModel.filterLocationsForWeather(locationsArray: self.locationManager.locationsArray)
        } catch let error as MethodError {
            self.methodErrorValue = error.description
        } catch {
            self.methodErrorValue = error.localizedDescription
        }
        //daten fertig bis auf puls,wetter,steigung
        let heartRateUnit:HKUnit = HKUnit(from: "count/min")
        self.hrErrorValue = ""
        self.weatherErrorValue = ""
            Publishers.Zip(self.infoViewModel.getWeatherData(urls: self.infoViewModel.urls), self.infoViewModel.getHrData(loc: self.locationManager.locationsArray))
                .tryMap { (weather, pulse) in
                    var heartRates:[Date:Double] = [:]
                    for h in pulse {
                        heartRates.updateValue(h.quantity.doubleValue(for: heartRateUnit), forKey: h.startDate)
                    }
                    try self.infoViewModel.calculateCalories(locArrayFirst: self.locationManager.locationsArray, weatherRes: weather, managedObjectContext: managedObjectContext, heartRates:  heartRates, user: self.user.user)
                    return (weather,pulse)
                }
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion:{ completion in
                    if case let .failure(error) = completion {
                        DispatchQueue.main.async {
                            if let er = error as? NetworkServiceError {
                                 // obj is a String. Do something with str
                                self.fileState = .wait4Weather
                                self.weatherErrorValue = er.localizedDescription
                              }
                              else if let er = error as? MethodError {
                                self.methodErrorValue = er.description
                              } else {
                                self.fileState = .wait4Hr
                                self.hrErrorValue = error.localizedDescription
                              }
                        }
                        print(error)
                    }
                }, receiveValue: { (weather: [Result]?, pulse: [HKQuantitySample]) in
                        for h in pulse {
                            self.infoViewModel.heartRates.updateValue(h.quantity.doubleValue(for: heartRateUnit), forKey: h.startDate)
                        }
                        self.infoViewModel.weatherResultArray = weather
                        self.fileState = .everythingSaved
                })
            .store(in: &cancellables)
    }
    
    func saveWeatherData() {
        
        self.hrErrorValue = ""
        self.weatherErrorValue = ""
        self.infoViewModel.getWeatherData(urls: self.infoViewModel.urls)
            .tryMap { (weather) throws -> [Result] in
                try self.infoViewModel.calculateCalories(locArrayFirst: self.locationManager.locationsArray, weatherRes: weather, managedObjectContext: managedObjectContext, heartRates:  self.infoViewModel.heartRates, user: self.user.user)
                return weather
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion:{ completion in
                if case let .failure(error) = completion {
                    DispatchQueue.main.async {
                        if let er = error as? NetworkServiceError {
                             // obj is a String. Do something with str
                            self.fileState = .wait4Weather
                            self.weatherErrorValue = er.localizedDescription
                          }
                          else if let er = error as? MethodError {
                            self.methodErrorValue = er.description
                          }
                  }
                }
            } , receiveValue: { (weather) in
                DispatchQueue.main.async {
                    self.infoViewModel.weatherResultArray = weather
                    self.fileState = .everythingSaved
                }
            })
            .store(in: &cancellables)
    }*/
    
}

/*   // https://www.dwd.de/DE/leistungen/windkarten/deutschland_und_bundeslaender.html
 // https://de.weatherspark.com/y/70344/Durchschnittswetter-in-München-Deutschland-das-ganze-Jahr-über*/
