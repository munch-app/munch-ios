//
// Created by Fuxing Loh on 17/3/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Alamofire

import SwiftyJSON

/**
 DiscoveryClient from DiscoveryService in munch-core/munch-api
 */
class DiscoverClient {
    let filter = FilterClient()

    func discover(query: SearchQuery, callback: @escaping (_ meta: MetaJSON, _ results: [SearchCard]) -> Void) {
        MunchApi.restful.post("/discover", parameters: query.toParams()) { meta, json in
            callback(meta, json["data"].map({ SearchCard(json: $0.1) }))
        }
    }

    class FilterClient {
        let decoder = JSONDecoder()

        func count(query: SearchQuery, callback: @escaping (_ meta: MetaJSON, _ filterData: FilterCount?) -> Void) {
            var query = query
            query.latLng = MunchLocation.lastLatLng

            MunchApi.restful.post("/discover/filter/count", parameters: query.toParams()) { meta, json in
                if meta.isOk() {
                    let filterData = try! self.decoder.decode(FilterCount.self, from: json["data"].rawData())
                    callback(meta, filterData)
                } else {
                    callback(meta, nil)
                }
            }
        }

        func price(query: SearchQuery, callback: @escaping (_ meta: MetaJSON, _ filterData: FilterPriceRange?) -> Void) {
            var query = query
            query.latLng = MunchLocation.lastLatLng

            MunchApi.restful.post("/discover/filter/price", parameters: query.toParams()) { meta, json in
                if meta.isOk() {
                    let filterData = try! self.decoder.decode(FilterPriceRange.self, from: json["data"].rawData())
                    callback(meta, filterData)
                } else {
                    callback(meta, nil)
                }
            }
        }
    }
}

struct FilterCount: Codable {
    var count: Int
    var tags: [String: Int]
}

struct FilterPriceRange: Codable {
    var frequency: [String: Int]

    var all: Segment
    var cheap: Segment
    var average: Segment
    var expensive: Segment

    struct Segment: Codable {
        var min: Double
        var max: Double

        var minRounded: Double {
            return (min / 5).rounded(.down) * 5
        }

        var maxRounded: Double {
            return (max / 5).rounded(.up) * 5
        }
    }
}