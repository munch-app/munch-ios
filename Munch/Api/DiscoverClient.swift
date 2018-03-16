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
    func discover(query: SearchQuery, callback: @escaping (_ meta: MetaJSON, _ results: [SearchCard]) -> Void) {
        MunchApi.restful.post("/discover", parameters: query.toParams()) { meta, json in
            callback(meta, json["data"].map({ SearchCard(json: $0.1) }))
        }
    }

    func filterSuggest(text: String, latLng: String?, query: SearchQuery, callback: @escaping (_ meta: MetaJSON,
                                                                                         _ locationContainers: [SearchResult],
                                                                                         _ tags: [Tag]) -> Void) {
        var params = Parameters()
        params["text"] = text
        params["latLng"] = latLng

        MunchLocation.waitFor { latLng, error in
            var query = query
            query.latLng = MunchLocation.lastLatLng
            params["query"] = query.toParams()

            MunchApi.restful.post("/discover/filter/suggest", parameters: params) { meta, json in
                let locationContainers = json["data"]["Location,Container"].flatMap({ SearchClient.parseResult(result: $0.1) })
                let tags = json["data"]["Tag"].flatMap({ SearchClient.parseResult(result: $0.1) as? Tag })
                callback(meta, locationContainers, tags)
            }
        }
    }

    func filterCount(query: SearchQuery, callback: @escaping (_ meta: MetaJSON, _ count: Int?) -> Void) {
        var query = query
        query.latLng = MunchLocation.lastLatLng

        MunchApi.restful.post("/discover/filter/count", parameters: query.toParams()) { meta, json in
            callback(meta, json["data"].int)
        }
    }

    func filterPriceRange(query: SearchQuery, callback: @escaping (_ meta: MetaJSON, _ priceRangeInArea: PriceRangeInArea?) -> Void) {
        var query = query
        query.latLng = MunchLocation.lastLatLng

        MunchApi.restful.post("/discover/filter/price/range", parameters: query.toParams()) { metaJSON, json in
            callback(metaJSON, PriceRangeInArea.init(json: json["data"]))
        }
    }
}