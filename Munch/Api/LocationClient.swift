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
            callback(meta, json["data"].map {
                Location.create(json: $0.1)!
            })
        }
    }

    func suggest(text: String, callback: @escaping (_ meta: MetaJSON, _ results: [SearchResult]) -> Void) {
        MunchApi.restful.get("/locations/suggest", parameters: ["text": text]) { meta, json in
            callback(meta, json["data"].compactMap({ SearchClient.parseResult(result: $0.1) }))
        }
    }

    func search(text: String, callback: @escaping (_ meta: MetaJSON, _ results: [SearchResult]) -> Void) {
        MunchApi.restful.get("/locations/search", parameters: ["text": text]) { meta, json in
            callback(meta, json["data"].compactMap({ SearchClient.parseResult(result: $0.1) }))
        }
    }
}

/**
 Location object form munch-core/service-location
 Used in search for munch-core/service-places
 */
struct Location: SearchResult, Equatable, Encodable, Decodable {
    static let decoder = JSONDecoder()

    var id: String?
    var name: String?
    var city: String?
    var country: String?

    var latLng: String?
    var points: [String]? // points is ["lat, lng"] String Array

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

    static func create(json: JSON) -> Location? {
        if (!json.exists()) {
            return nil
        }

        return try? decoder.decode(Location.self, from: try! json.rawData())
    }
}
