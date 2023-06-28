//
//  MapView.swift
//  RideTracker
//
//  Created by Martina Hinz on 17.04.21.
//
import MapKit
import SwiftUI


struct MapView: UIViewRepresentable  {
    var locationArray: [Location]
    var region: MKCoordinateRegion
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.setRegion(region, animated: true)
        map.delegate = context.coordinator
       map.addOverlays(polyLine())
        return map
    }
    
    func makeCoordinator() -> MapCoordinator {
        MapCoordinator(self)
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
    }
    
    func polyLine() -> [MulticolorPolyline] {
        var segments: [MulticolorPolyline] = []
        var coordinates: [(CLLocation, CLLocation)] = []
        var speeds: [Double] = []
        var minSpeed = Double.greatestFiniteMagnitude
        var maxSpeed = 0.0
        
        
        // 2
        for (idx,l) in locationArray.enumerated() {
            if l.isEqual(locationArray.last) || idx == locationArray.count{
                break
            }
     //   for (first, second) in zip(locationArray, locationArray.dropFirst()) {
            let start = CLLocation(latitude: l.latitude, longitude: l.longitude)
            let end = CLLocation(latitude: locationArray[idx+1].latitude, longitude: locationArray[idx+1].longitude)
         //   let speed = (l.speed + locationArray[idx+1].speed)/2.0
            let segment = MulticolorPolyline(coordinates: [start.coordinate, end.coordinate], count: 2)
            switch l.speed {
            case l.speed where 0..<5 ~= l.speed:
                segment.color = UIColor(.green)
            case l.speed where 5..<10 ~= l.speed:
                segment.color = UIColor(.orange)
            case l.speed where 10..<15 ~= l.speed:
                segment.color = UIColor(.red)
            default:
                segment.color = UIColor(.pink)
                
            }
            segments.append(segment)
//            coordinates.append((start, end))
            
            //3
//            let distance = end.distance(from: start)
//            let time = second.timestamp!.timeIntervalSince(first.timestamp! as Date)
//            let speed = time > 0 ? distance / time : 0
//            speeds.append(first.speed)
//            minSpeed = min(minSpeed, speed)
//            maxSpeed = max(maxSpeed, speed)
        }
        
        //4
     //   let midSpeed = speeds.reduce(0, +) / Double(speeds.count)
        
        //5
//        var segments: [MulticolorPolyline] = []
//        for ((start, end), speed) in zip(coordinates, speeds) {
//            let coords = [start.coordinate, end.coordinate]
//            let segment = MulticolorPolyline(coordinates: coords, count: 2)
//            switch speed {
//            case speed where 0..<5 ~= speed:
//                segment.color = UIColor(.green)
//            case speed where 5..<10 ~= speed:
//                segment.color = UIColor(.orange)
//            case speed where 10..<15 ~= speed:
//                segment.color = UIColor(.red)
//            default:
//                segment.color = UIColor(.pink)
//
//            }
           /* segment.color = segmentColor(speed: speed,
                                         midSpeed: midSpeed,
                                         slowestSpeed: minSpeed,
                                         fastestSpeed: maxSpeed)*/
          //  segments.append(segment)
        //}
        return segments
    }
    
    private func segmentColor(speed: Double, midSpeed: Double, slowestSpeed: Double, fastestSpeed: Double) -> UIColor {
        enum BaseColors {
            static let r_red: CGFloat = 1
            static let r_green: CGFloat = 20 / 255
            static let r_blue: CGFloat = 44 / 255
            
            static let y_red: CGFloat = 1
            static let y_green: CGFloat = 215 / 255
            static let y_blue: CGFloat = 0
            
            static let g_red: CGFloat = 0
            static let g_green: CGFloat = 146 / 255
            static let g_blue: CGFloat = 78 / 255
        }
        
        let red, green, blue: CGFloat
        
        if speed < midSpeed {
            let ratio = CGFloat((speed - slowestSpeed) / (midSpeed - slowestSpeed))
            red = BaseColors.r_red + ratio * (BaseColors.y_red - BaseColors.r_red)
            green = BaseColors.r_green + ratio * (BaseColors.y_green - BaseColors.r_green)
            blue = BaseColors.r_blue + ratio * (BaseColors.y_blue - BaseColors.r_blue)
        } else {
            let ratio = CGFloat((speed - midSpeed) / (fastestSpeed - midSpeed))
            red = BaseColors.y_red + ratio * (BaseColors.g_red - BaseColors.y_red)
            green = BaseColors.y_green + ratio * (BaseColors.g_green - BaseColors.y_green)
            blue = BaseColors.y_blue + ratio * (BaseColors.g_blue - BaseColors.y_blue)
        }
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
}


