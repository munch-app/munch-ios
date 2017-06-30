//
//  Location.swift
//  Munch
//
//  Created by Fuxing Loh on 1/7/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import SwiftLocation

/**
 Delegated Munch App User Location tracker
 */
public class MunchLocation {
    
    /**
     Last latLng of userLocation, can be nil
     */
    public static var lastLatLng: String?
    
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
     Wait util first location is available
     */
    public class func waitFor(completion: @escaping (_ latLng: String?, _ error: Error?) -> Void) {
        // Already have latLng
        if let latLng = lastLatLng {
            completion(latLng, nil)
        } else {
            SwiftLocation.Location.getLocation(accuracy: .neighborhood, frequency: .oneShot, success: { request, location in
                let coord = location.coordinate
                MunchLocation.lastLatLng = "\(coord.latitude),\(coord.longitude)"
                completion(lastLatLng, nil)
            }, error: { _, _, err in
                completion(lastLatLng, err)
            })
        }
    }
    
    /**
     Start location monitoring
     This method update lastLocation to lastLatLng
     */
    public class func startMonitoring() {
        SwiftLocation.Location.getLocation(accuracy: .block, frequency: .significant, success: { request, location in
            let coord = location.coordinate
            MunchLocation.lastLatLng = "\(coord.latitude),\(coord.longitude)"
        }, error: { _, _, _ in
        })
    }
}
