//
//  MapCoordinator.swift
//  RideTracker
//
//  Created by Martina Hinz on 17.04.21.
//

import Foundation
import MapKit

final class MapCoordinator: NSObject, MKMapViewDelegate {
    var control: MapView
    
    init(_ control: MapView) {
        self.control = control
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let routePolyline = overlay as? MulticolorPolyline {
                let renderer = MKPolylineRenderer(polyline: routePolyline)
                renderer.strokeColor = routePolyline.color
                renderer.lineWidth = 3
                return renderer
            }

            return MKOverlayRenderer()
    }
}

import UIKit

class MulticolorPolyline: MKPolyline {
  var color = UIColor.black
}


extension MKPolyline {
   
}
