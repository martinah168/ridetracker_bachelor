//
//  MapboxView.swift
//  RideTracker
//
//  Created by Martina Hinz on 17.05.21.
//

import Foundation
import SwiftUI
/*import Mapbox

extension MGLPointAnnotation {
    convenience init(title: String, coordinate: CLLocationCoordinate2D) {
        self.init()
        self.title = title
        self.coordinate = coordinate
    }
}

struct MapboxView: UIViewRepresentable {
    @Binding var annotations: [MGLPointAnnotation]
    private let mapView: MGLMapView = MGLMapView(frame: .zero, styleURL: MGLStyle.streetsStyleURL)

    func makeUIView(context: UIViewRepresentableContext<MapboxView>) -> MGLMapView {
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ uiView: MGLMapView, context: UIViewRepresentableContext<MapboxView>) {

    }
    
    func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
    func styleURL(_ styleURL: URL) -> MapboxView {
            mapView.styleURL = styleURL
            return self
        }
        
        func centerCoordinate(_ centerCoordinate: CLLocationCoordinate2D) -> MapboxView {
            mapView.centerCoordinate = centerCoordinate
            return self
        }
        
        func zoomLevel(_ zoomLevel: Double) -> MapboxView {
            mapView.zoomLevel = zoomLevel
            return self
        }
        
        private func updateAnnotations() {
            if let currentAnnotations = mapView.annotations {
                mapView.removeAnnotations(currentAnnotations)
            }
            mapView.addAnnotations(annotations)
        }
}
*/
