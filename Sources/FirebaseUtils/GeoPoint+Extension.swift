//
//  File.swift
//  
//
//  Created by Mooseok Bahng on 2023/07/17.
//

import FirebaseFirestore
import CoreLocation

extension GeoPoint {
    public static func fromCoordinate(_ coordinate: CLLocationCoordinate2D) -> GeoPoint {
        GeoPoint(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
}
