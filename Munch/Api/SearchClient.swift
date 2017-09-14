//
//  SearchClient.swift
//  Munch
//
//  Created by Fuxing Loh on 14/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import UIKit
import Foundation
import Alamofire
import SwiftyJSON

/**
 DiscoveryClient from DiscoveryService in munch-core/munch-api
 */
class SearchClient: RestfulClient {
    func suggest(text: String, size: Int, latLng: String? = nil, callback: @escaping (_ meta: MetaJSON, _ results: [SearchResult]) -> Void) {
        var params = Parameters()
        params["text"] = text
        params["size"] = size
        params["latLng"] = latLng
        
        super.post("/search/suggest", parameters: params) { meta, json in
            callback(meta, SearchCollection.parseList(searchResult: json["data"]))
        }
    }
    
    func collections(query: SearchQuery, callback: @escaping (_ meta: MetaJSON, _ collections: [SearchCollection]) -> Void) {
        super.post("/search/collections", parameters: query.toParams()) { meta, json in
            callback(meta, json["data"].map { SearchCollection(json: $0.1) })
        }
    }
    
    func collectionsSearch(query: SearchQuery, callback: @escaping (_ meta: MetaJSON, _ results: [SearchResult]) -> Void) {
        super.post("/search/collections/search", parameters: query.toParams()) { meta, json in
            callback(meta, SearchCollection.parseList(searchResult: json["data"]))
        }
    }
}

/**
 Possible types are:
 - Place
 - Location
 */
protocol SearchResult {
}

/**
 SearchQuery object from munch-core/service-places
 This is a input and output data
 
 - from: pagination from
 - size: pagination size
 - query: search query string
 */
struct SearchQuery: Equatable {
    var from: Int?
    var size: Int?
    
    var query: String?
    var latLng: String?
    var location: Location?
    
    var filter: Filter
    var sort: Sort
    
    init() {
        filter = Filter()
        sort = Sort()
    }
    
    init(json: JSON) {
        self.from = json["from"].int
        self.size = json["size"].int
        
        self.query = json["query"].string
        self.latLng = json["latLng"].string
        self.location = Location(json: json["location"])
        
        self.filter = Filter(json: json["filter"])
        self.sort = Sort(json: json["sort"])
    }
    
    struct Filter {
        var price = Price()
        var tag = Tag()
        var hour = Hour()
        
        init() {
            
        }
        
        init(json: JSON) {
            price.min = json["price"]["min"].double
            price.max = json["price"]["max"].double
            
            tag.positives = json["tag"]["positives"].arrayValue.map { $0.stringValue }
            tag.negatives = json["tag"]["negatives"].arrayValue.map { $0.stringValue }
            
            hour.day = json["hour"]["day"].string
            hour.time = json["hour"]["time"].string
            
        }
        
        struct Price {
            var min: Double?
            var max: Double?
            
        }
        
        struct Tag {
            var positives: [String]?
            var negatives: [String]?
        }
        
        struct Hour {
            var day: String?
            var time: String?
        }
        
        func toParams() -> Parameters {
            var params = Parameters()
            params["price"] = ["min": price.min, "max": price.max]
            params["tag"] = ["positives": tag.positives, "negatives": tag.negatives]
            params["hour"] = ["day": hour.day, "time": hour.time]
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
    
    /**
     Map to Alamofire supported parameters encoding
     */
    func toParams() -> Parameters {
        var params = Parameters()
        params["from"] = from
        params["size"] = size
        
        params["query"] = query
        params["location"] = location?.toParams()
        
        params["filter"] = filter.toParams()
        params["sort"] = sort.toParams()
        return params
    }
    
    static func == (lhs: SearchQuery, rhs: SearchQuery) -> Bool {
        return NSDictionary(dictionary: lhs.toParams()).isEqual(to: rhs.toParams())
    }
}

/**
 SearchCollection object from munch-core/munch-api
 used for containing a collection
 */
struct SearchCollection {
    let name: String
    let query: SearchQuery
    let results: [SearchResult]
    
    init(json: JSON) {
        self.name = json["name"].stringValue
        self.query = SearchQuery(json: json["query"])
        self.results = SearchCollection.parseList(searchResult: json["results"])
    }
    
    init(name: String, query: SearchQuery, results: [SearchResult]){
        self.name = name
        self.query = query
        self.results = results
    }
    
    /**
     Method to parse search result type
     */
    public static func parse(searchResult json: JSON) -> SearchResult? {
        switch json["type"].stringValue {
        case "Place": return Place(json: json)
        case "Location": return Location(json: json)
        default: return nil
        }
    }
    
    /**
     Parse only search item
     */
    public static func parseList(searchResult json: JSON) -> [SearchResult] {
        var results = [SearchResult]()
        for each in json {
            if let item = parse(searchResult: each.1) {
                results.append(item)
            }
        }
        return results
    }
}
