//
//  Location.swift
//  Munch
//
//  Created by Fuxing Loh on 1/7/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import SwiftLocation
import CoreLocation

/**
 Delegated Munch App User Location tracker
 */
public class MunchLocation {
    
    /**
     Last latLng of userLocation, can be nil
     */
    private static var lastLatLng: String?
    private static var lastLocation: CLLocation?
    
    // Expiry every 200 seconds
    private static var expiryIncrement: TimeInterval = 200
    private static var locationExpiry = Date().addingTimeInterval(expiryIncrement)
    
    /**
     Check if location service is enabled
     */
    public class var enabled: Bool {
        switch (SwiftLocation.LocAuth.status) {
        case .alwaysAuthorized, .inUseAuthorized:
            return true
        default:
            return false
        }
    }
    
    /**
     Wait util an accurate location is available
     */
    public class func waitFor(completion: @escaping (_ latLng: String?, _ error: Error?) -> Void) {
        // Already have latLng
        if let latLng = lastLatLng, locationExpiry > Date() {
            completion(latLng, nil)
        } else {
            SwiftLocation.Location.getLocation(accuracy: .block, frequency: .oneShot, success: { request, location in
                let coord = location.coordinate
                MunchLocation.lastLatLng = "\(coord.latitude),\(coord.longitude)"
                MunchLocation.lastLocation = location
                
                locationExpiry = Date().addingTimeInterval(expiryIncrement)
                completion(lastLatLng, nil)
            }, error: { _, _, err in
                completion(lastLatLng, err)
            })
        }
    }
    
    /**
     Get latLng immediately
     And schedule a load once
     */
    public class func getLatLng() -> String? {
        if (enabled) {
            scheduleOnce()
        }
        if let latLng = lastLatLng {
            return latLng
        }
        return nil
    }
    
    /**
     Start location monitoring
     This method update lastLocation to lastLatLng
     */
    public class func scheduleOnce() {
        SwiftLocation.Location.getLocation(accuracy: .block, frequency: .oneShot, success: { request, location in
            let coord = location.coordinate
            MunchLocation.lastLatLng = "\(coord.latitude),\(coord.longitude)"
            MunchLocation.lastLocation = location
            
            locationExpiry = Date().addingTimeInterval(expiryIncrement)
        }, error: { _, _, err in
            print(err)
        })
    }
    
    /**
     Distance from current location in metres
     */
    public class func distance(latLng: String) -> Double? {
        if let locationA = MunchLocation.lastLocation, let locationB = CLLocation(latLng: latLng) {
            return locationA.distance(from: locationB)
        }
        return nil
    }
    
    /**
     For < 1km format metres in multiple of 50s
     For < 100km format with 1 precision floating double
     For > 100km format in km
     */
    public class func distance(asMetric latLng: String) -> String? {
        if let distance = distance(latLng: latLng) {
            if (distance < 1000) {
                let m = (distance/50).roundTo(places: 0)
                return "\(m)m"
            } else if (distance < 100000) {
                let demical = (distance/1000).roundTo(places: 1)
                return "\(demical)km"
            } else {
                return "\(Int(distance/1000))km"
            }
        }
        return nil
    }
}

extension CLLocation {
    
    convenience init?(latLng: String) {
        let ll = latLng.components(separatedBy: ",")
        if let lat = ll.get(0), let lng = ll.get(1) {
            if let latD = Double(lat), let lngD = Double(lng) {
                self.init(latitude: latD, longitude: lngD)
                return
            }
        }
        return nil
    }
    
}
