//
//  LocationsClient.swift
//  Munch
//
//  Created by Fuxing Loh on 14/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

/**
 LocationClient from LocationService in munch-core/munch-api
 that is direct proxy to LocationService in munch-core/service-location
 */
class LocationClient {
    func popular(callback: @escaping (_ meta: MetaJSON, _ locations: [Location]) -> Void) {
        MunchApi.restful.get("/locations/popular") { meta, json in
            callback(meta, json["data"].map { Location(json: $0.1)! })
        }
    }
    
    func suggest(text: String, callback: @escaping (_ meta: MetaJSON, _ results: [SearchResult]) -> Void) {
        MunchApi.restful.get("/locations/suggest", parameters: ["text": text]) { meta, json in
            callback(meta, json["data"].flatMap({ SearchClient.parseResult(result: $0.1) }))
        }
    }

    func search(text: String, callback: @escaping (_ meta: MetaJSON, _ results: [SearchResult]) -> Void) {
        MunchApi.restful.get("/locations/search", parameters: ["text": text]) { meta, json in
            callback(meta, json["data"].flatMap({ SearchClient.parseResult(result: $0.1) }))
        }
    }
}

/**
 Location object form munch-core/service-location
 Used in search for munch-core/service-places
 */
struct Location: SearchResult, Equatable {
    var id: String?
    var name: String?
    var city: String?
    var country: String?
    
    var latLng: String?
    var points: [String]? // points is ["lat, lng"] String Array

    init() {

    }

    init?(json: JSON) {
        if (!json.exists()) { return nil }
        
        self.id = json["id"].string
        self.name = json["name"].string
        self.city = json["city"].string
        self.country = json["country"].string
        
        self.latLng = json["latLng"].string
        self.points = json["points"].map({$0.1.stringValue})
    }
    
    func toParams() -> Parameters {
        var params = Parameters()
        params["id"] = id
        params["name"] = name
        params["city"] = city
        params["country"] = country
        
        params["latLng"] = latLng
        params["points"] = points
        params["dataType"] = "Location"
        return params
    }

    static func ==(lhs: Location, rhs: Location) -> Bool {
        return lhs.id == rhs.id
    }
}
