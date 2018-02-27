//
//  Location.swift
//  Munch
//
//  Created by Fuxing Loh on 1/7/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import CoreLocation

import SwiftLocation

/**
 Delegated Munch App User Location tracker
 */
public class MunchLocation {

    // Last latLng of userLocation, can be nil
    public static var lastLatLng: String?
    public static var lastLocation: CLLocation?

    // Expiry every 200 seconds
    private static var expiryIncrement: TimeInterval = 200
    private static var locationExpiry = Date().addingTimeInterval(expiryIncrement)

    /**
     Check if location service is enabled
     */
    public class var isEnabled: Bool {
        switch (Locator.state) {
        case .available:
            return true
        default:
            return false
        }
    }

    public class var lastCoordinate: CLLocationCoordinate2D? {
        return self.lastLocation?.coordinate
    }

    public class func requestLocation() {
        switch Locator.state {
        case .notDetermined:
            MunchLocation.scheduleOnce()
        case .disabled:
            if let url = URL(string: "App-Prefs:root=Privacy&path=LOCATION") {
                UIApplication.shared.open(url)
            }
        case .denied:
            if let url = URL(string: "App-Prefs:root=Privacy&path=LOCATION/co.munch.MunchApp") {
                UIApplication.shared.open(url)
            }
        default: break
        }
    }

    /**
     Wait util an accurate location is available
     Will return nil latLng if not found
     */
    public class func waitFor(completion: @escaping (_ latLng: String?, _ error: Error?) -> Void) {
        if (!isEnabled) {
            // If not enabled, just return nil latLng
            completion(nil, nil)
        } else if let latLng = lastLatLng, locationExpiry > Date() {
            // Already have latLng, and not yet expired
            completion(latLng, nil)
        } else {
            // Location already expired, query again
            Locator.currentPosition(accuracy: .city, timeout: .delayed(15), onSuccess: { (location) -> (Void) in
                let coord = location.coordinate
                MunchLocation.locationExpiry = Date().addingTimeInterval(expiryIncrement)
                MunchLocation.lastLatLng = "\(coord.latitude),\(coord.longitude)"
                MunchLocation.lastLocation = location

                completion(lastLatLng, nil)
            }) { (error, location) -> (Void) in
                completion(lastLatLng, error)
            }
        }
    }

    /**
     Get latLng immediately
     And schedule a load once
     */
    public class func getLatLng() -> String? {
        if (isEnabled) {
            scheduleOnce()
        }
        return lastLatLng
    }

    /**
     Start location monitoring
     This method update lastLocation to lastLatLng
     */
    public class func scheduleOnce() {
        Locator.currentPosition(accuracy: .city, onSuccess: { (location) -> (Void) in
            let coord = location.coordinate
            MunchLocation.lastLatLng = "\(coord.latitude),\(coord.longitude)"
            MunchLocation.lastLocation = location

            locationExpiry = Date().addingTimeInterval(expiryIncrement)
        }) { (error, location) in
            // Failed to schedule once, no feedback required for this.
            print(error)
        }
    }

    /**
     Distance from current location in metres
     */
    public class func distance(latLng: String?, toLatLng: String? = MunchLocation.lastLatLng) -> Double? {
        if let latLngA = toLatLng, let locationA = CLLocation(latLng: latLngA),
           let latLngB = latLng, let locationB = CLLocation(latLng: latLngB) {
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
            if (distance <= 10.0) {
                return "10m"
            } else if (distance <= 50.0) {
                return "50m"
            } else if (distance < 1000) {
                let m = (Int(distance / 50) * 50)
                if (m == 1000) {
                    return "1.0km"
                } else {
                    return "\(m)m"
                }
            } else if (distance < 100000) {
                let decimal = (distance / 1000).roundTo(places: 1)
                return "\(decimal)km"
            } else {
                return "\(Int(distance / 1000))km"
            }
        }
        return nil
    }

    public class func distance(asDuration latLng: String?, toLatLng: String? = lastLatLng) -> String? {
        if let distance = distance(latLng: latLng, toLatLng: toLatLng) {
            let minute = Int(distance / 70)
            if (minute <= 1) {
                return "1 min"
            }
            return "\(minute) min"
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
