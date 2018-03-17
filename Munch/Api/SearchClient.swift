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

class SearchClient {
    func search(text: String, latLng: String?, query: SearchQuery, callback: @escaping (_ meta: MetaJSON,
                                                                        _ assumptions: [AssumptionQueryResult],
                                                                        _ places: [Place]) -> Void) {
        var params = Parameters()
        params["text"] = text
        params["latLng"] = latLng

        MunchLocation.waitFor { latLng, error in
            var query = query
            query.latLng = MunchLocation.lastLatLng
            params["query"] = query.toParams()

            MunchApi.restful.post("/search", parameters: params) { meta, json in
                let assumptions = json["data"]["assumptions"].flatMap({ AssumptionQueryResult(json: $0.1) })
                let places = json["data"]["places"].flatMap({ SearchClient.parseResult(result: $0.1) as? Place })
                callback(meta, assumptions, places)
            }
        }
    }



    /**
     Method to parse search result type
     */
    public static func parseResult(result json: JSON?) -> SearchResult? {
        if let json = json {
            switch json["dataType"].stringValue {
            case "Tag": return Tag(json: json)
            case "Place": return Place(json: json)
            case "Location": return Location(json: json)
            case "Container": return Container(json: json)
            default: return nil
            }
        }
        return nil
    }
}

struct PriceRangeInArea {
    var avg: Double
    var min: Double
    var max: Double

    var cheapRange: PriceRange
    var averageRange: PriceRange
    var expensiveRange: PriceRange

    struct PriceRange {
        init(json: JSON) {
            self.min = json["min"].doubleValue
            self.max = json["max"].doubleValue
        }

        var min: Double
        var max: Double
    }

    init?(json: JSON) {
        guard json.exists() else {
            return nil
        }
        self.avg = json["avg"].doubleValue
        self.min = json["min"].doubleValue
        self.max = json["max"].doubleValue

        self.cheapRange = .init(json: json["cheapRange"])
        self.averageRange = .init(json: json["averageRange"])
        self.expensiveRange = .init(json: json["expensiveRange"])
    }

    var minRounded: Double {
        return (min / 5).rounded(.down) * 5
    }

    var maxRounded: Double {
        return (max / 5).rounded(.up) * 5
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
struct Tag: SearchResult {
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

struct Container: SearchResult, Equatable {
    var id: String?
    var type: String?
    var name: String?

    var images: [SourcedImage]?
    var ranking: Double

    var location: Location?

    struct Location {
        var latLng: String?

        init(json: JSON) {
            self.latLng = json["latLng"].string
        }
    }

    init(json: JSON) {
        self.id = json["id"].string
        self.type = json["type"].string
        self.name = json["name"].string

        self.images = json["images"].map({ SourcedImage(json: $0.1) })
        self.ranking = json["ranking"].double ?? 0

        self.location = Location(json: json["location"])
    }

    func toParams() -> Parameters {
        var params = Parameters()
        params["id"] = id
        params["type"] = type
        params["name"] = name

        params["images"] = images?.map({ $0.toParams() })
        params["ranking"] = ranking

        params["dataType"] = "Container"
        return params
    }

    static func ==(lhs: Container, rhs: Container) -> Bool {
        return lhs.id == rhs.id
    }
}

struct AssumptionQueryResult {
    var searchQuery: SearchQuery
    var tokens: [SearchQueryToken]
    var places: [Place]

    init?(json: JSON) {
        guard json.exists() else {
            return nil
        }
        self.searchQuery = SearchQuery(json: json["searchQuery"])
        self.tokens = json["tokens"].flatMap({ AssumptionQueryResult.parseToken(result: $0.1) })
        self.places = json["places"].flatMap({ SearchClient.parseResult(result: $0.1) as? Place })
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

/**
 SearchQuery object from munch-core/service-places
 This is a input and output data
 */
struct SearchQuery: Equatable {
    var from: Int? = 0
    var size: Int? = 20
    var query: String? // Visual Representation of SearchQuery

    var latLng: String?
    var radius: Double?

    var filter: Filter
    var sort: Sort
    var trigger: Trigger

    init() {
        filter = Filter()
        sort = Sort()
        trigger = Trigger()
    }

    init(json: JSON) {
        self.from = json["from"].int
        self.size = json["size"].int

        self.query = json["query"].string
        self.latLng = json["latLng"].string
        self.radius = json["radius"].double

        self.filter = Filter(json: json["filter"])
        self.sort = Sort(json: json["sort"])
        self.trigger = Trigger(json: json["trigger"])
    }

    struct Filter {
        var price = Price()
        var tag = Tag()
        var hour = Hour()
        var location: Location?
        var containers: [Container]?

        init() {

        }

        init(json: JSON) {
            price.name = json["price"]["name"].string
            price.min = json["price"]["min"].double
            price.max = json["price"]["max"].double

            tag.positives = Set(json["tag"]["positives"].arrayValue.map({ $0.stringValue }))

            hour.name = json["hour"]["name"].string
            hour.day = json["hour"]["day"].string
            hour.open = json["hour"]["open"].string
            hour.close = json["hour"]["close"].string

            location = Location(json: json["location"])
            containers = json["containers"].map({ Container(json: $0.1) })
        }

        struct Price {
            var name: String?
            var min: Double?
            var max: Double?
        }

        struct Tag {
            var positives = Set<String>()
        }

        struct Hour {
            var name: String?

            var day: String?
            var open: String?
            var close: String?
        }

        func toParams() -> Parameters {
            var params = Parameters()
            params["price"] = ["name": price.name as Any, "min": price.min as Any, "max": price.max as Any]
            params["tag"] = ["positives": Array(tag.positives)]
            params["hour"] = ["name": hour.name, "day": hour.day, "open": hour.open, "close": hour.close]
            params["location"] = location?.toParams()
            params["containers"] = containers?.map({ $0.toParams() })
            return params
        }
    }

    struct Sort {
        // See MunchCore for the available sort methods
        var type: String?

        init() {

        }

        init(json: JSON) {
            type = json["sort"]["type"].string
        }

        func toParams() -> Parameters {
            var params = Parameters()
            params["type"] = type
            return params
        }
    }

    struct Trigger {
        var querySearch: Int
        var placeClick: Int
        var placeImpression: Int
        var PlacePosition: Int

        init() {
            self.querySearch = 0
            self.placeClick = 0
            self.placeImpression = 0
            self.PlacePosition = 0
        }

        init(json: JSON) {
            self.querySearch = json["querySearch"].int ?? 0
            self.placeClick = json["placeClick"].int ?? 0
            self.placeImpression = json["placeImpression"].int ?? 0
            self.PlacePosition = json["PlacePosition"].int ?? 0
        }

        func toParams() -> Parameters {
            var params = Parameters()
            params["querySearch"] = querySearch
            params["placeClick"] = placeClick
            params["placeImpression"] = placeImpression
            params["PlacePosition"] = PlacePosition
            return params
        }
    }

    /**
     Map to Alamofire supported parameters encoding
     */
    func toParams() -> Parameters {
        var params = Parameters()
        params["from"] = from
        params["size"] = size
        params["query"] = query

        params["latLng"] = latLng
        params["radius"] = radius

        params["filter"] = filter.toParams()
        params["sort"] = sort.toParams()
        params["trigger"] = trigger.toParams()
        return params
    }

    static func ==(lhs: SearchQuery, rhs: SearchQuery) -> Bool {
        guard (lhs.query == rhs.query) else {
            return false
        }

        guard (NSDictionary(dictionary: lhs.filter.toParams()).isEqual(to: rhs.filter.toParams())) else {
            return false
        }

        guard (NSDictionary(dictionary: lhs.sort.toParams()).isEqual(to: rhs.sort.toParams())) else {
            return false
        }
        return true
    }
}

/**
 Search typed Cards
 Access json through the subscript
 */
struct SearchCard: Equatable {
    var cardId: String
    var uniqueId: String?
    var instanceId: String
    private var json: JSON

    init(cardId: String, json: JSON = JSON(parseJSON: "{}")) {
        self.cardId = cardId
        self.instanceId = String(arc4random())
        self.json = json
    }

    init(json: JSON) {
        self.cardId = json["_cardId"].stringValue
        self.uniqueId = json["_uniqueId"].string
        self.instanceId = String(arc4random())
        self.json = json
    }

    /**
     Subscript to get data from json with its name
     */
    subscript(name: String) -> JSON {
        return json[name]
    }

    static func ==(lhs: SearchCard, rhs: SearchCard) -> Bool {
        return lhs.cardId == rhs.cardId && lhs.uniqueId == rhs.uniqueId
    }
}
