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

import RxSwift

/**
 Delegated Munch App User Location tracker
 */
public class MunchLocation {

    // Last latLng of userLocation, can be nil
    public static var lastLatLng: String?
    public static var lastLocation: CLLocation?
    public class var lastCoordinate: CLLocationCoordinate2D? {
        return self.lastLocation?.coordinate
    }

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

    private class func requestPermission() -> Single<Bool> {
        if isEnabled {
            return Single<Bool>.create { single in
                single(.success(true))
                return Disposables.create()
            }
        }

        return Single<Bool>.create { single in
            switch Locator.state {
            case .notDetermined:
                Locator.requestAuthorizationIfNeeded(.whenInUse)
                single(.success(true))

            case .disabled:
                if let url = URL(string: "\(UIApplicationOpenSettingsURLString)&path=LOCATION") {
                    UIApplication.shared.open(url)
                }

            case .denied:
                if let bundleId = Bundle.main.bundleIdentifier,
                   let url = URL(string: "\(UIApplicationOpenSettingsURLString)&path=LOCATION/\(bundleId)") {
                    UIApplication.shared.open(url)
                }
            default: break
            }

            single(.success(false))
            return Disposables.create()
        }
    }

    // force: Location is cached in Munch, force will reset the cache and get it from provider immediately
    // permission: User have perform action that require location, add this flag so it will notify user asking for location
    public class func request(force: Bool = false, permission: Bool = false) -> Single<String?> {
        if isEnabled {
            return requestLocation(force: force)
        }

        if permission {
            return requestPermission().flatMap { _ -> Single<String?> in
                return requestLocation(force: force)
            }
        }

        return Single<String?>.create { single in
            single(.success(nil))
            return Disposables.create()
        }
    }

    private class func requestLocation(force: Bool = false) -> Single<String?> {
        return Single<String?>.create { single in
            // Actually request the permission
            if let latLng = lastLatLng, locationExpiry > Date(), !force {
                single(.success(latLng))
                return Disposables.create()
            } else {
                let locating = Locator.currentPosition(accuracy: .city, timeout: .delayed(5), onSuccess: { (location) -> (Void) in
                    let coord = location.coordinate
                    MunchLocation.locationExpiry = Date().addingTimeInterval(expiryIncrement)
                    MunchLocation.lastLatLng = "\(coord.latitude),\(coord.longitude)"
                    MunchLocation.lastLocation = location

                    single(.success(MunchLocation.lastLatLng))
                }) { (error, location) -> (Void) in
                    single(.error(error))
                }

                return Disposables.create {
                    locating.stop()
                }
            }
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
        let ll = latLng.split(separator: ",")
        if let lat = ll.get(0)?.trimmingCharacters(in: .whitespacesAndNewlines),
           let lng = ll.get(1)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if let latD = Double(lat), let lngD = Double(lng) {
                self.init(latitude: latD, longitude: lngD)
                return
            }
        }
        return nil
    }
}

extension Array where Element == CLLocation {
    var centroid: CLLocation {
        var cLat = 0.0, cLng = 0.0

        self.forEach { (v: CLLocation) in
            cLat += v.coordinate.latitude
            cLng += v.coordinate.longitude
        }

        return CLLocation(latitude: cLat / Double(self.count), longitude: cLng / Double(self.count))
    }
}