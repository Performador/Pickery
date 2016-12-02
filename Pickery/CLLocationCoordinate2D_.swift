//
//  CLLocationCoordinate2D_.swift
//  Pickery
//
//  Created by Okan Arikan on 10/20/16.
//
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D {
    
    /// Figure out the distance between two coordinates
    func metersTo(coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let thisLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let otherLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        return thisLocation.distance(from: otherLocation)
    }
}
