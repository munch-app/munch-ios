//
//  Ingest.swift
//  Munch
//
//  Created by Fuxing Loh on 27/3/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Spatial {
    let lat: Double
    let lng: Double
    
    init(lat: Double, lng: Double) {
        self.lat = lat
        self.lng = lng
    }
    
    func parameters() -> [String : Any] {
        return ["lat": lat, "lng": lng]
    }
}
