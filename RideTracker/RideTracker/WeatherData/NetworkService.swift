//
//  NetworkService.swift
//  RideTracker
//
//  Created by Martina Hinz on 18.04.21.
//

import Foundation
import Combine

class NetworkService {
    static let shared = NetworkService()
    
    let URL_SAMPLE = "https://api.openweathermap.org/data/2.5/onecall?lat=60.99&lon=30.9&exclude=minutely,hourly,daily,alerts&appid=5d3493506d875c7585914fcd96097edd"
    let URL_API_KEY = "5d3493506d875c7585914fcd96097edd"
    var URL_LATTITUDE = "60.99"
    var URL_LONGITUDE = "30.0"
    var URL_Date = "19.08.2000"
    var URL_EXCLUDE = "minutely,hourly,daily,alerts"
    var URL_GET_ONE_CALL = ""
    let URL_BASE = "https://api.openweathermap.org/data/2.5/onecall/timemachine?"
    
    let session = URLSession(configuration: .default)
    
    func buildURL() -> String {
        URL_GET_ONE_CALL = "lat=" + URL_LATTITUDE + "&lon=" + URL_LONGITUDE + "&dt=" + URL_Date + "&units=metric" + "&appid=" + URL_API_KEY
        return URL_BASE + URL_GET_ONE_CALL
    }
    
    func setLatitude(_ latitude: String) {
        URL_LATTITUDE = latitude
    }
    
    func setLatitude(_ latitude: Double) {
        setLatitude(String(latitude))
    }
    
    func setLongitude(_ longitude: String) {
        URL_LONGITUDE = longitude
    }
    
    func setLongitude(_ longitude: Double) {
        setLongitude(String(longitude))
    }
    
    func setDate(_ date: String) {
        URL_Date = date
    }
    
    func setDate(_ date: Date) {
        setDate(String(format: "%.0f", date.timeIntervalSince1970))
    }
    
    func getWeatherData(url: String) -> AnyPublisher<Result, Error> {
        guard let url = URL(string: url) else {
            return Fail(error: NetworkServiceError.cannotComposeUrl).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { output in
                if let error = try? JSONDecoder().decode(ServerError.self, from: output.data) {
                    throw NetworkServiceError.decodingError(description: error.error)
                }
                guard let response = output.response as? HTTPURLResponse, response.statusCode == 200 else {
                    throw NetworkServiceError.wrongStatusCode
                }
                return output.data
            }
            .decode(type: Result.self, decoder: JSONDecoder()).eraseToAnyPublisher()
            .mapError { error -> NetworkServiceError in
                if let error = error as? NetworkServiceError {
                    return error
                } else {
                    return NetworkServiceError.unknownError(description: error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
}


protocol NetworkError: Error {
    var description: String { get }
}

struct ServerError: Codable {
    let error: String
}

enum NetworkServiceError: NetworkError {
    
    case nonImplemented
    case cannotComposeUrl
    case wrongStatusCode
    case decodingError(description: String)
    case unknownError(description: String)
    
    var description: String {
        switch self {
        case .unknownError(let desc):
            return "unknown error: \(desc)"
        case .decodingError(let desc):
            return "decoding error \(desc)"
        case .wrongStatusCode:
            return "wrong status code"
        case .nonImplemented:
            return "Function not implemented"
        case .cannotComposeUrl:
            return "Cannot compose URL"
        }
    }
}
