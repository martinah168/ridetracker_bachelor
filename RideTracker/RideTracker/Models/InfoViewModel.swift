//
//  InfoViewModel.swift
//  RideTracker
//
//  Created by Martina Hinz on 20.04.21.
//
import SwiftUI
import HealthKit
import MapKit
import Combine
import CoreData
import CoreLocation
import WatchConnectivity

enum FileState {
    case nothingSaved
    case hrSaved
    case everythingSaved
    case wait4Hr
    case wait4Weather
}

enum MethodError: Error {
    case locationSavingError
    case locationUnrwappingError
    case emptyLocation
    case emptyWeather
    case weatherAPIError
    case caloriesError
    case hrError
    case coreLocError
    case csvError
    case hkError
    case notificiationError
    case buildURLS
    
    var description: String {
        switch self {
        
        case .locationSavingError:
            return "location saving error:"
        case .locationUnrwappingError:
            return "location unwrapping error"
        case .emptyLocation:
            return "empty location error: No location was saved"
        case .emptyWeather:
            return "empty weather error: No weather was saved"
        case .weatherAPIError:
            return "weatherAPIError"
        case .caloriesError:
            return "calories error: Calculation of calories went wrong"
        case .hrError:
            return "heartrate error"
        case .coreLocError:
            return "coreLocError"
        case .csvError:
            return "csvError"
        case .hkError:
            return "hk error"
        case .notificiationError:
            return "notification error"
        case .buildURLS:
            return "buliding urls error"
        }
    }
}


class InfoViewModel: ObservableObject {
    @Published var calories: [Double] = []
        @Published var hrErrorValue = ""
        @Published var weatherErrorValue = ""
        @Published var methodErrorValue = ""
        @Published var fileState: FileState = .nothingSaved
    /*@Published*/ var urls: [String] = []
    @Published var loading = false
        
    var weatherResultArray: [Result]? = nil
    var weatherResults: [WeatherCore] = []
    private(set) var cancellables = Set<AnyCancellable>()
    var heartRates: [Date:Double] = [:]
    var slopes: [Double] = []
    var idxWeather: [Int] = []
    
    var watchCommunication = ViewModelPhone()
    
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
    
    func filterLocationsForWeather(locationsArray: [CLLocation]?) throws {
        guard let locArray = locationsArray else {
            print("error locationArray empty")
            throw MethodError.emptyLocation
        }
        do {
            self.idxWeather.removeAll()
            
            var startDate = locArray.first?.timestamp ?? Date()
            var startDistance = 0.0
            
            for (index,loc) in locArray.enumerated() {
                if startDate.distance(to: loc.timestamp) > TimeInterval(3600) || startDistance > 5000.0 || index == 0 {
                    startDate = loc.timestamp
                    startDistance = 0.0
                    NetworkService.shared.setLatitude(loc.coordinate.latitude)
                    NetworkService.shared.setLongitude(loc.coordinate.longitude)
                    NetworkService.shared.setDate(loc.timestamp)
                    let url = NetworkService.shared.buildURL()
                    urls.append(url)
                    idxWeather.append(index)
                }
                if(index < locArray.count-1) {
                    guard locArray.indices.contains(index+1) else {
                        throw MethodError.buildURLS
                    }
                    let location1 = CLLocation(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
                    let location2 = CLLocation(latitude: locArray[index+1].coordinate.latitude, longitude: locArray[index+1].coordinate.longitude)
                    startDistance += abs(location1.distance(from: location2))
                }
            }
        } catch {
            throw MethodError.buildURLS
        }
        
    }
    
    func getWeatherData(urls: [String]) -> AnyPublisher<[Result], Error> {
        //send all weather requests
        //        weatherErrorValue = ""
        
        let req = urls.map { url in
            NetworkService.shared.getWeatherData(url: url)
                .mapError { error -> Error in
                    if let error = error as? NetworkServiceError {
                        return error
                    } else {
                        return NetworkServiceError.nonImplemented
                    }
                }
                .eraseToAnyPublisher()
        }
        
        return Publishers.MergeMany(req)
            .collect()
            .mapError {
                error -> Error  in
                return error
            }
            .eraseToAnyPublisher()
    }
    
    func getHrData(loc: [CLLocation]) -> AnyPublisher<[HKQuantitySample], Error>{
        
        return HealthKitSetupAssistant.fetchLatestHeartRateSample(startDate: loc.first?.timestamp ?? Date(), endDate: loc.last?.timestamp ?? Date())
            .mapError { error -> Error  in
                return error
            }
            .eraseToAnyPublisher()
    }
    
    func saveHrData(loc: [CLLocation], managedObjectContext: NSManagedObjectContext, user: User) {
        do {
            try self.filterLocationsForWeather(locationsArray: loc)
        } catch let error as MethodError {
            self.methodErrorValue = error.description
        } catch {
            self.methodErrorValue = error.localizedDescription
        }
        //daten fertig bis auf puls,wetter,steigung
        let heartRateUnit:HKUnit = HKUnit(from: "count/min")
        
            Publishers.Zip(self.getWeatherData(urls: self.urls), self.getHrData(loc: loc))
                .tryMap { (weather, pulse) in
                    var heartRates:[Date:Double] = [:]
                    var cal: [Double] = []
                  //  print("Executed on background thread")
                    for h in pulse {
                        heartRates.updateValue(h.quantity.doubleValue(for: heartRateUnit), forKey: h.startDate)
                    }
                    cal = try self.calculateCalories(locArrayFirst: loc, weatherRes: weather, managedObjectContext: managedObjectContext, heartRates:  heartRates, user: user)
                       
                    return (weather,pulse,cal)
                }
//                .tryMap { (weather, pulse) in
//                    var heartRates:[Date:Double] = [:]
//                    var cal: [Double] = []
//                    DispatchQueue.global(qos: .background).async {
//                        do {
//                            print("Executed on background thread")
//                            for h in pulse {
//                                heartRates.updateValue(h.quantity.doubleValue(for: heartRateUnit), forKey: h.startDate)
//                            }
//                            cal = try self.calculateCalories(locArrayFirst: loc, weatherRes: weather, managedObjectContext: managedObjectContext, heartRates:  heartRates, user: user)
//                        } catch let error as MethodError {
//                           self.methodErrorValue = error.description
//                        } catch  {
//                            self.methodErrorValue = error.localizedDescription
//                        }
//                    }
//                    return (weather,pulse,cal)
//                }
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion:{ completion in
                    if case let .failure(error) = completion {
                     //   DispatchQueue.main.async {
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
                      //  }
                        self.loading = false
                        print(error)
                    }
                }, receiveValue: { (weather: [Result]?, pulse: [HKQuantitySample], cal: [Double]) in
                   // DispatchQueue.main.async {
                        for h in pulse {
                            self.heartRates.updateValue(h.quantity.doubleValue(for: heartRateUnit), forKey: h.startDate)
                        }
                        self.weatherResultArray = weather
                        self.calories = cal
                        self.fileState = .everythingSaved
                        self.loading = false
                  //  }
                })
            .store(in: &cancellables)
    }
    
    func saveWeatherData(loc: [CLLocation], managedObjectContext: NSManagedObjectContext, user: User) {
        
        self.getWeatherData(urls: self.urls)
           // .receive(on: DispatchQueue.main)
            .tryMap { (weather) throws -> ([Result]?, [Double]) in
                var calc: [Double] = []
                DispatchQueue.global(qos: .background).async {
                    do {
                      calc = try self.calculateCalories(locArrayFirst:loc, weatherRes: weather, managedObjectContext: managedObjectContext, heartRates:  self.heartRates, user: user)
                    } catch let error as MethodError {
                       self.methodErrorValue = error.description
                    } catch  {
                        self.methodErrorValue = error.localizedDescription
                    }
                }
                /*DispatchQueue.main.async {
                    self.calories = calc
                }*/
                return (weather,calc)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion:{ completion in
                if case let .failure(error) = completion {
                   // DispatchQueue.main.async {
                        if let er = error as? NetworkServiceError {
                             // obj is a String. Do something with str
                            self.fileState = .wait4Weather
                            self.weatherErrorValue = er.localizedDescription
                          }
                          else if let er = error as? MethodError {
                            self.methodErrorValue = er.description
                    //      }
                  }
                self.loading = false
                }
            } , receiveValue: { (weather: [Result]?, calc: [Double]) in
          //      DispatchQueue.main.async {
                    self.weatherResultArray = weather
                    self.calories = calc
                    self.fileState = .everythingSaved
                self.loading = false
        //        }
            })
            .store(in: &cancellables)
    }
    //TODO enum error to encode state weather & puls
    /**
     Gets weather data from an API, fetches heart rate samples from HealthKit and calculates calories for ride afterwards
     
     
     - Parameters:
     - urls: URLS to get weather data for every GPS point from the openweathermap API
     - loc: location array with all GPS points from the cycling route
     */
    #warning("TODO: split into 2 Publishers and chain together")
   /* func getData(urls: [String], loc: [CLLocation], managedObjectContext: NSManagedObjectContext, user: User) {
        let heartRateUnit:HKUnit = HKUnit(from: "count/min")

        let req = urls.map { url in
            NetworkService.shared.getWeatherData(url: url )
                .mapError { error -> NetworkServiceError in
                    if let error = error as? NetworkServiceError {
                        //                        self.fileState = .wait4Weather
                        //                        self.weatherErrorValue = error.localizedDescription
                        return error
                    } else {
                        //                        self.fileState = .wait4Weather
                        //                        self.weatherErrorValue = error.localizedDescription
                        return NetworkServiceError.nonImplemented
                    }
                }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        //fetch heartrate from Health Kit
        
        let p = Publishers.MergeMany(req)
            .collect()
            .mapError {
                error -> Error  in
                //                self.fileState = .wait4Weather
                //                self.weatherErrorValue = error.localizedDescription
                return error
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        
        let hk = HealthKitSetupAssistant.fetchLatestHeartRateSample(startDate: loc.first?.timestamp ?? Date(), endDate: loc.last?.timestamp ?? Date())
            .mapError { error -> Error  in
                //                self.fileState = .wait4Hr
                //                self.hrErrorValue = error.localizedDescription
                return error
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        //calculate Calories after receiving weather data and heart rates
        Publishers.Zip(p, hk)
            .sink(receiveCompletion:{ completion in
                if case let .failure(error) = completion {
                    //                    if let er = error as? NetworkServiceError {
                    //                         // obj is a String. Do something with str
                    //                        self.fileState = .wait4Weather
                    //                        self.weatherErrorValue = er.localizedDescription
                    //                      }
                    //                      else {
                    //                        self.fileState = .wait4Hr
                    //                        self.hrErrorValue = error.localizedDescription
                    //                      }
                    print(error)
                }
            }, receiveValue: { (weather, heartR) in
                DispatchQueue.main.async {
                    self.weatherResultArray = weather
                    for h in heartR {
                        self.heartRates.updateValue(h.quantity.doubleValue(for: heartRateUnit), forKey: h.startDate)
                    }
                    //
                    self.fileState = .everythingSaved
                    do {
                    try self.calculateCalories(locArrayFirst: loc, managedObjectContext: managedObjectContext, user: user )
                    }
                    catch
                }
            })
            .store(in: &cancellables)
    }*/
    
    
    private func calculateAirVelocity(windDirection: Int,
                                      riderDirection: Double,
                                      windSpeed: Double,
                                      riderSpeed: Double) -> Double  {
        let windTan = windSpeed * cos(Double(windDirection)-riderDirection)
        let vA = riderSpeed + windTan
        return vA
    }
    
    private func calculateAirDensity(temp: Double, pressure: Int ) -> Double {
        let kelvin = 273.15
        let temperatureInKelvin = temp + kelvin
        let calcAirDensity = ((Double(pressure)*100.0) / (287.058*temperatureInKelvin))
        return (calcAirDensity == 0 ? 1.2 : calcAirDensity)
    }
    
    private func calculatePedalingForce(mass: Double, deltaH: Double, v2: Double, v1: Double, deltaS: Double, airDensity: Double, windDrag: Double, coeff: Double) -> Double {
        let cA = coeff
        let Epot = mass * 9.81 * deltaH
        let Ekin = mass * 0.5 * (pow(v2,2) - pow(v1,2))
        let Eair = cA * airDensity * pow(windDrag,2)
        
        let pedalingForce = -(Epot + Ekin - Eair)
        return pedalingForce
    }
    
    func calculateCalories(locArrayFirst: [CLLocation], weatherRes: [Result]?, managedObjectContext: NSManagedObjectContext, heartRates: [Date:Double],  user: User) throws -> [Double] {
        guard var weather = weatherRes else {
            print("returned bc of weather array")
            throw MethodError.emptyWeather
        }
        weather.sort{$0.current.dt < $1.current.dt}
        print("Weather size: \(weather.count)")
        
        if locArrayFirst.isEmpty || locArrayFirst.count <= 1 {
            print("returned bc of loc array")
            throw MethodError.emptyLocation
        }
        var caloriesArr: [Double] = []
        //set first values as default values
        var currentWindDirection: Int = weather[0].current.wind_deg
        var currentWindSpeed: Double = weather[0].current.wind_speed
        var currentTemp: Double = weather[0].current.temp
        var currentPressure: Int = weather[0].current.pressure
        
        let mass = user.bikeWeight + user.weightInKilograms
        let gravitation = 9.81
        let femaleCal = user.biologicalSex == HKBiologicalSex.female ? true : false
        
        var currentCourse = locArrayFirst.first?.course ?? 0
        var currentSpeed = locArrayFirst.first?.speed ?? 0.0
        
        var i = 0
        for (index, loc) in locArrayFirst.enumerated() {
            #warning("indices error?")
            guard !idxWeather.isEmpty else {
                throw MethodError.caloriesError
            }
            if (i < weather.count && i < idxWeather.count && index == idxWeather[i]) {
                guard weather.indices.contains(i) else {
                    throw MethodError.caloriesError
                }
                currentTemp = weather[i].current.temp
                currentPressure = weather[i].current.pressure
                currentWindDirection = weather[i].current.wind_deg
                currentWindSpeed = weather[i].current.wind_speed
                i += 1
            }
            self.weatherResults.append(WeatherCore(windDirection: currentWindDirection, windSpeed: currentWindSpeed, pressure: currentPressure, temp: currentTemp))
            
            currentCourse = loc.course != -1 ? loc.course : currentCourse
            currentSpeed = loc.speed == -1 ? currentSpeed : loc.speed
            
            let windDrag = self.calculateAirVelocity(windDirection: currentWindDirection, riderDirection: currentCourse, windSpeed: currentWindSpeed, riderSpeed: currentSpeed)
            
            let airDensity = self.calculateAirDensity(temp: currentTemp, pressure: currentPressure)
            
            var slope = 0.0
            var deltaH = 0.0
            var v1 = 0.0
            var v2 = 0.0
            var deltaD = 0.0
            var deltaV = 0.0
            if (index > 0) {
                guard locArrayFirst.indices.contains(index), locArrayFirst.indices.contains(index-1) else {
                    throw MethodError.caloriesError
                }
                deltaH = locArrayFirst[index].altitude - locArrayFirst[index-1].altitude
                deltaV = pow(locArrayFirst[index].speed,2) - pow(locArrayFirst[index-1].speed,2)
            } else {
                guard locArrayFirst.indices.contains(index), locArrayFirst.indices.contains(index+1) else {
                    throw MethodError.caloriesError
                }
                deltaH = locArrayFirst[index+1].altitude - locArrayFirst[index].altitude
                deltaV = pow(locArrayFirst[index+1].speed,2) - pow(locArrayFirst[index].speed,2)
            }
            var Epot = mass * gravitation*deltaH
            var Ekin = 0.5 * mass * deltaV
            slopes.append(0.0)
            /*    if(index > 0 ) {
                guard locArrayFirst.indices.contains(index), locArrayFirst.indices.contains(index-1) else {
                    throw MethodError.caloriesError
                }
                
                deltaD = abs(locArrayFirst[index-1].distance(from: locArrayFirst[index]))
                
                deltaH = locArrayFirst[index].altitude - locArrayFirst[index-1].altitude
                slope = deltaH / deltaD
                v1 = locArrayFirst[index-1].speed
                v2 = loc.speed
            } else {
                guard locArrayFirst.indices.contains(index), locArrayFirst.indices.contains(index+1) else {
                    throw MethodError.caloriesError
                }
                
                deltaD = abs(locArrayFirst[index].distance(from: locArrayFirst[index+1]))
                
                deltaH = locArrayFirst[index+1].altitude - locArrayFirst[index].altitude
                slope = deltaH / deltaD
         v1 = loc.speed
                v2 = locArrayFirst[index+1].speed
            }
            slopes.append(slope)
                var pedalingEnergy = 0.0
            if (slope < 0 && currentSpeed >= 0 && currentCourse >= 0) {
                let windD = self.calculateAirVelocity(windDirection: currentWindDirection, riderDirection: currentCourse, windSpeed: currentWindSpeed, riderSpeed: v2-v1)
                pedalingEnergy  = self.calculatePedalingForce(mass: mass, deltaH: deltaH, v2: v2, v1: v1, deltaS: deltaD, airDensity: airDensity, windDrag: windD, coeff: user.coefficientD)
            }*/
          //  var pedalingEnergy = 0.0
            if (currentSpeed < 0 || currentCourse < 0 ) {//|| (pedalingEnergy <= 0 && slope < 0)) {
                caloriesArr.append(0.0)
            } else {
              /*  if pedalingEnergy > 0 {
                    caloriesArr.append(pedalingEnergy/4184.0)
                } else {*/
                    let cA = user.coefficientD
                    let cR = user.coefficientR
                    
                    let forceR = (mass*gravitation*cR*currentSpeed)/4184
//                    let forceAir = airDensity * cA * pow(windDrag,2)
                    let forceAir = (airDensity * cA * windDrag * abs(windDrag)*currentSpeed)/4184
                let ee = (Epot+Ekin+forceR+forceAir)/4184
                if ee < 0 {
                    caloriesArr.append(0.0)
                } else {
                    let c = femaleCal ? (ee)/1.47 : ee
                    caloriesArr.append(c)
                }
                   // let p = ((forceG + forceAir)*currentSpeed)*0.25
//                    let p = (forceG * currentSpeed + forceAir)*0.25
                  //  let c = femaleCal ? (p/1000.0)/1.47 : p/1000.0
                  //  caloriesArr.append(c)
                //}
            }
        }
        var pausenumsatz = Double(user.basalMetablicRate/3600)
        var nonEx = Double(locArrayFirst.count)*pausenumsatz
        var ex = caloriesArr.reduce(0.0,+)*(100/user.efficiencyRate)
        var totalCal = ex + nonEx-21.231
        
        var distance = 0.0
        for (index,loc) in locArrayFirst.enumerated() {
            if index != locArrayFirst.count-1{
                guard locArrayFirst.indices.contains(index+1) else {
                    throw MethodError.caloriesError
                }
                distance += loc.distance(from: locArrayFirst[index+1])
            }
        }
        
        print("saving into files and health kit")
        try self.saveToCSVFile(locArray: locArrayFirst, weatherResults: self.weatherResults, heartRates: heartRates, caloriesArr: caloriesArr)
        try self.saveToHK(startDate: locArrayFirst.first?.timestamp,
                      endDate: locArrayFirst.last?.timestamp,
                      locDistance: distance, caloriesArr: caloriesArr)
        try self.saveRide(distance: distance,
                      duration: locArrayFirst.first?.timestamp.distance(to: locArrayFirst.last?.timestamp ?? Date()) ?? 0,
                      calories: totalCal,
                      locations: locArrayFirst
                      , managedObjectContext: managedObjectContext)
        return caloriesArr
    }
    
    private func saveToCSVFile(locArray: [CLLocation], weatherResults: [WeatherCore], heartRates: [Date:Double], caloriesArr: [Double]) throws {
        var locationArray:[Dictionary<String, AnyObject>] =  Array()
        var puls = -1.0
        let sortedHR = heartRates.sorted(by: { $0.0 < $1.0 })
        for (index,loc) in locArray.enumerated() {
            puls =  sortedHR.filter {Calendar.current.isDate($0.key, equalTo: loc.timestamp, toGranularity: .second)}.first?.value ?? puls
            var dct = Dictionary<String, AnyObject>()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
            formatter.timeZone = TimeZone(abbreviation: "CEST")
            let date =  formatter.string(from: loc.timestamp)
            
            dct.updateValue(date as AnyObject, forKey: "Timestamp")
            dct.updateValue(loc.coordinate.latitude as AnyObject, forKey: "Latitude")
            dct.updateValue(loc.coordinate.longitude as AnyObject, forKey: "Longitude")
            dct.updateValue(loc.course as AnyObject, forKey: "Course")
            dct.updateValue(puls as AnyObject, forKey: "Heart Rate")
            dct.updateValue(loc.speed as AnyObject, forKey: "Speed")
            guard slopes.indices.contains(index) else {
                throw MethodError.csvError
            }
            dct.updateValue(slopes[index] as AnyObject, forKey: "Slope")
            dct.updateValue(loc.altitude as AnyObject, forKey: "Altitude")
            guard caloriesArr.indices.contains(index) else {
                throw MethodError.csvError
            }
            dct.updateValue(caloriesArr[index] as AnyObject, forKey: "KiloCalories")
            guard weatherResults.indices.contains(index) else {
                throw MethodError.csvError
            }
            dct.updateValue(weatherResults[index].windDirection as AnyObject, forKey: "Wind Direction")
            dct.updateValue(weatherResults[index].windSpeed as AnyObject, forKey: "Wind Speed")
            dct.updateValue(weatherResults[index].pressure as AnyObject, forKey: "Pressure")
            dct.updateValue(weatherResults[index].temp as AnyObject, forKey: "Temperature")
            locationArray.append(dct)
        }
        
    /*    var heartRateArray:[Dictionary<String, AnyObject>] =  Array()
        for hr in heartRates {
            var dct = Dictionary<String, AnyObject>()
            dct.updateValue(hr.key as AnyObject, forKey: "Timestamp")
            dct.updateValue(hr.value as AnyObject, forKey: "Puls")
            heartRateArray.append(dct)
        }
        var csvString = "\("Timestamp"), \("Puls")\n\n"
        for dct in heartRateArray {
            csvString = csvString.appending("\(String(describing: dct["Timestamp"]!)),\(String(describing: dct["Puls"]!))\n")
        }
        do {
            let dateFormatter: DateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy_MMM_dd_HH_mm_ss"
            let date = Date()
            let dateString = dateFormatter.string(from: date)
            
            
            //var url =  URL(fileURLWithPath: "/Users/martina/Documents/BA_CSVFiles")
            var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            url.appendPathComponent("CSVPuls_\(dateString)_.csv")
            try csvString.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }*/
       try createCSV(from: locationArray)
    }
    
    ///save ride to a CSV on the device
    private func createCSV(from recArray:[Dictionary<String, AnyObject>]) throws {
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
            print("\(url)")
            try csvString.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
            throw MethodError.csvError
        }
        
    }
    
    ///save ride to core data
    private func saveRide(distance: Double, duration: Double, calories: Double, locations: [CLLocation], managedObjectContext: NSManagedObjectContext) throws {
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
            guard weatherResults.indices.contains(index) else {
                throw MethodError.csvError
            }
            locationObject.windSpeed = weatherResults[index].windSpeed
            locationObject.windDirection = Int64(exactly: weatherResults[index].windDirection) ?? -1
            newRide.addToRideToLocations(locationObject)
        }
        PersistanceManager.shared.save()
    }
    
    private func saveToHK(startDate: Date?, endDate: Date?, locDistance: Double, caloriesArr: [Double]) throws {
        let totalBurnCal = caloriesArr.reduce(0.0,+)
        
        guard let startDate = startDate, let endDate = endDate else {
            throw MethodError.hkError
        }
        
        let calorie = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: totalBurnCal)
        
        let distance = HKQuantity(unit: HKUnit.meter(), doubleValue: locDistance)
        
        let workout = HKWorkout(activityType: .cycling, start: startDate, end: endDate, duration: startDate.distance(to: endDate), totalEnergyBurned: calorie, totalDistance: distance, metadata: nil)

        HKHealthStore().save(workout) { (success: Bool, error: Error?) -> Void in
            if success {
                //Workout was successfully saved
            }
            else {
                
            }
        }
    }
}
