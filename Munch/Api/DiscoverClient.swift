//
// Created by Fuxing Loh on 17/3/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Alamofire

import SwiftyJSON
import Crashlytics
import Cache

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
        let locations = LocationClient()
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
                guard meta.isOk() else {
                    callback(meta, nil)
                    return
                }

                let filterData = try? self.decoder.decode(FilterPriceRange.self, from: json["data"].rawData())
                callback(meta, filterData)
            }
        }

        class LocationClient {
            private let decoder = JSONDecoder()
            private let storage: Storage?

            init() {
                do {
                    let diskConfig = DiskConfig(name: "api.discover.filter.locations")
                    let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
                    self.storage = try Storage(diskConfig: diskConfig, memoryConfig: memoryConfig)
                } catch {
                    self.storage = nil
                    print(error)
                    Crashlytics.sharedInstance().recordError(error)
                }
            }

            func list(callback: @escaping (_ meta: MetaJSON, _ locations: [Location], _ containers: [Container]) -> Void) {
                if let storage = storage {
                    try? storage.removeExpiredObjects()
                    let locations = try? storage.object(ofType: [Location].self, forKey: "locations")
                    let containers = try? storage.object(ofType: [Container].self, forKey: "containers")
                    if let locations = locations, let containers = containers {
                        callback(.ok, locations, containers)
                        return
                    }
                }


                MunchApi.restful.get("/discover/filter/locations/list") { meta, json in
                    guard meta.isOk() else {
                        callback(meta, [], [])
                        return
                    }

                    var locations = [Location]()
                    var containers = [Container]()

                    if let array = json["data"].array {
                        for data in array {
                            let result = SearchClient.parseResult(result: data)
                            if let location = result as? Location {
                                locations.append(location)
                            } else if let container = result as? Container {
                                containers.append(container)
                            }
                        }
                    }

                    if let storage = self.storage {
                        try? storage.setObject(locations, forKey: "locations", expiry: .seconds(60 * 60 * 25))
                        try? storage.setObject(containers, forKey: "containers", expiry: .seconds(60 * 60 * 25))
                    }
                    callback(meta, locations, containers)
                }
            }

            func search(text: String, callback: @escaping (_ meta: MetaJSON, _ results: [SearchResult]) -> Void) {
                MunchApi.restful.get("/discover/filter/locations/search", parameters: ["text": text]) { meta, json in
                    callback(meta, json["data"].compactMap({ SearchClient.parseResult(result: $0.1) }))
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