//
//  SearchClient.swift
//  Munch
//
//  Created by Fuxing Loh on 14/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import Alamofire

import SwiftyJSON
import Toast_Swift

class SearchClient {
    private static let decoder = JSONDecoder()

    func search(text: String, latLng: String?, query: SearchQuery, callback: @escaping (_ meta: MetaJSON,
                                                                                        _ suggests: [String],
                                                                                        _ assumptions: [AssumptionQueryResult],
                                                                                        _ places: [DeprecatedPlace]) -> Void) {
        var params = Parameters()
        params["text"] = text
        params["latLng"] = latLng

        MunchLocation.waitFor { latLng, error in
            var query = query
            query.latLng = MunchLocation.lastLatLng
            params["query"] = query.toParams()

            MunchApi.restful.post("/search/search", parameters: params) { meta, json in
                let data = json["data"]
                let suggests = data["suggests"].compactMap({ $0.1.string })
                let assumptions = data["assumptions"].compactMap({ AssumptionQueryResult(json: $0.1) })
                let places = data["places"].compactMap({ SearchClient.parseResult(result: $0.1) as? DeprecatedPlace })
                callback(meta, suggests, assumptions, places)
            }
        }
    }


    /**
     Method to parse search result type
     */
    public static func parseResult(result json: JSON?) -> SearchResult? {
        if let json = json {
            switch json["dataType"].stringValue {
            case "Tag": return DeprecatedTag(json: json)
            case "Place": return DeprecatedPlace(json: json)

            case "Location":
                return try? decoder.decode(DeprecatedLocation.self, from: try! json.rawData())

            case "Container":
                return try? decoder.decode(Container.self, from: try! json.rawData())
            default: return nil
            }
        }
        return nil
    }
}

/**
 Possible types are:
 - Place
 - Location
 - Tag
 */
protocol SearchResult {
}

/**
 Tag object from munch-core/munch-data
 */
struct DeprecatedTag: SearchResult {
    var id: String?
    var name: String?

    init(name: String) {
        self.name = name
    }

    init(json: JSON) {
        self.id = json["id"].string
        self.name = json["name"].string
    }

    func toParams() -> Parameters {
        var params = Parameters()
        params["id"] = id
        params["name"] = name
        params["dataType"] = "Tag"
        return params
    }
}

struct AssumptionQueryResult {
    var searchQuery: SearchQuery
    var tokens: [SearchQueryToken]
    var places: [DeprecatedPlace]
    var count: Int

    init?(json: JSON) {
        guard json.exists() else {
            return nil
        }
        self.searchQuery = SearchQuery(json: json["searchQuery"])
        self.tokens = json["tokens"].compactMap({ AssumptionQueryResult.parseToken(result: $0.1) })
        self.places = json["places"].compactMap({ SearchClient.parseResult(result: $0.1) as? DeprecatedPlace })
        self.count = json["count"].int ?? 0
    }

    struct TextToken: SearchQueryToken {
        var text: String
    }

    struct TagToken: SearchQueryToken {
        var text: String
    }

    public static func parseToken(result json: JSON?) -> SearchQueryToken? {
        if let json = json {
            switch json["type"].stringValue {
            case "text": return TextToken(text: json["text"].string ?? "")
            case "tag": return TagToken(text: json["text"].string ?? "")
            default: return nil
            }
        }
        return nil
    }
}

protocol SearchQueryToken {

}
