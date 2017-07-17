//
//  RestfulClient.swift
//  Munch
//
//  Created by Fuxing Loh on 23/3/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import UIKit
import Foundation
import Alamofire
import SwiftyJSON

public class RestfulClient {
    public static var lastLatLng: String?
    
    private let url: String
    
    init(_ url: String) {
        self.url = url
    }
    
    /**
     Params Encoding is query string
     */
    fileprivate func get(_ path: String, parameters: Parameters = [:], callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        request(method: .get, path: path, parameters: parameters, encoding: URLEncoding.default, callback: callback)
    }
    
    /**
     Params Encoding is json
     */
    fileprivate func post(_ path: String, parameters: Parameters = [:], callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        request(method: .post, path: path, parameters: parameters, encoding: JSONEncoding.default, callback: callback)
    }
    
    /**
     method: HttpMethod
     path: After domain
     paramters: json or query string both supported
     encoding: encoding of paramters
     callback: Meta and Json
     */
    fileprivate func request(method: HTTPMethod, path: String, parameters: Parameters, encoding: ParameterEncoding, callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        var headers = [String: String]()
        
        // Set latLng if available
        if let latLng = MunchLocation.getLatLng() {
            headers["Location-LatLng"] = latLng
        }
        
        Alamofire.request(url + path, method: method, parameters: parameters, encoding: encoding, headers: headers)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    callback(MetaJSON(metaJson: json["meta"]), json)
                case .failure(let error):
                    // TODO error handling
                    // - Offline
                    // - Timeout
                    print(error)
                }
        }
    }
}

/**
 Meta Json in response
 {meta: {}}
 */
public struct MetaJSON {
    public let code: Int!
    public let error: Error?
    
    public struct Error {
        public let type: String?
        public let message: String?
        
        public init(errorJson: JSON){
            self.type = errorJson["type"].string
            self.message = errorJson["message"].string
        }
    }
    
    public init(metaJson: JSON){
        self.code = metaJson["code"].intValue
        if metaJson["error"].exists() {
            self.error = Error(errorJson: metaJson["error"])
        }else{
            self.error = nil
        }
    }
    
    /**
     Returns true if meta is successful
     */
    public func isOk() -> Bool {
        return code == 200
    }
    
    /**
     Create an UI Alert Controller with prefilled info to
     easily print error message as alert dialog
     */
    public func createAlert() -> UIAlertController {
        let type = error?.type ?? "Unknown Error"
        let message = error?.message ?? "An unknown error has occured."
        let alert = UIAlertController(title: type, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        return alert
    }
}

let MunchApi = MunchClient.instance

public class MunchClient: RestfulClient {
    public static let instance = MunchClient()
    
    private static let baseUrl = MunchPlist.get(asString: "MunchApiBaseUrl-Beta")!
    
    let discovery = DiscoveryClient(baseUrl)
    let places = PlaceClient(baseUrl)
    let locations = LocationClient(baseUrl)
    let cached = CachedSyncClient(baseUrl)
    
    private init() {
        super.init(MunchClient.baseUrl)
    }
}

/**
 DiscoveryClient from DiscoveryService in munch-core/munch-api
 */
class DiscoveryClient: RestfulClient {
    func suggest(text: String, size: Int, latLng: String? = nil, callback: @escaping (_ meta: MetaJSON, _ results: [SearchResult]) -> Void) {
        var params = Parameters()
        params["text"] = text
        params["size"] = size
        params["latLng"] = latLng
        
        super.post("/discovery/suggest", parameters: params) { meta, json in
            callback(meta, SearchCollection.parseList(searchResult: json["data"]))
        }
    }
    
    func search(query: SearchQuery, callback: @escaping (_ meta: MetaJSON, _ collections: [SearchCollection], _ streetName: String?) -> Void) {
        super.post("/discovery/search", parameters: query.toParams()) { meta, json in
            callback(meta, json["data"].map { SearchCollection(json: $0.1) }, json["street"]["name"].string)
        }
    }
    
    func searchNext(query: SearchQuery, callback: @escaping (_ meta: MetaJSON, _ results: [SearchResult]) -> Void) {
        super.post("/discovery/search/next", parameters: query.toParams()) { meta, json in
            callback(meta, SearchCollection.parseList(searchResult: json["data"]))
        }
    }
}

/**
 PlaceClient from PlaceService in munch-core/munch-api
 */
class PlaceClient: RestfulClient {
    func get(id: String, callback: @escaping (_ meta: MetaJSON, _ place: PlaceDetail?) -> Void) {
        super.get("/places/\(id)") { meta, json in
            callback(meta, PlaceDetail(json: json["data"]))
        }
    }
    
    func medias(id: String, from: Int, size: Int, callback: @escaping (_ meta: MetaJSON, _ medias: [Media]) -> Void) {
        super.get("/places/\(id)/instagram/medias/list", parameters: ["from": from, "size": size]) { meta, json in
            callback(meta, json["data"].map({Media(json: $0.1)}))
        }
    }
    
    func articles(id: String, from: Int, size: Int, callback: @escaping (_ meta: MetaJSON, _ articles: [Article]) -> Void) {
        super.get("/places/\(id)/articles/list", parameters: ["from": from, "size": size]) { meta, json in
            callback(meta, json["data"].map({Article(json: $0.1)}))
        }
    }
}

/**
 Offline place testing tools
 */
extension PlaceClient {
    private class func randomCollection() -> [SearchCollection] {
        return [
            SearchCollection(name: "NEARBY", query: SearchQuery(), results: randomPlaces()),
            SearchCollection(name: "HEALTHY OPTIONS", query: SearchQuery(), results: randomPlaces()),
            SearchCollection(name: "CAFES", query: SearchQuery(), results: randomPlaces()),
            SearchCollection(name: "PUBS & BARS", query: SearchQuery(), results: [])
        ]
    }
    
    private class func randomPlaces() -> [Place] {
        var place1 = Place()
        place1.name = "Char-Grill Bar"
        place1.tags = ["Western", "Bar", "Restaurant"]
        place1.images = [ImageMeta(images: ["1082x976": "http://2.bp.blogspot.com/-TtLzNIIy7k4/T9zBgKVwmBI/AAAAAAAAAoQ/u3o820ef0_c/s1600/_DSC8145.jpg"])]
        
        var place2 = Place()
        place2.name = "Isteak Diner"
        place2.tags = ["Western", "Steak", "Restaurant"]
        place2.images = [ImageMeta(images: ["1024x683": "https://c4.staticflickr.com/9/8879/27776438723_dc366674ed_b.jpg"])]
        
        var place3 = Place()
        place3.name = "The Daily Cut"
        place3.tags = ["Western", "Salad", "Restaurant"]
        place3.images = [ImageMeta(images: ["640x480": "http://lh4.googleusercontent.com/-olXUBLvg834/VSo53q_7cqI/AAAAAAAADeU/5tnAT6r9GAQ/s640/blogger-image-796908253.jpg"])]
        
        var place4 = Place()
        place4.name = "Nandos"
        place4.tags = ["Chicken", "Grill", "Restaurant"]
        place4.images = [ImageMeta(images: ["1037x691": "https://ohhhoney.files.wordpress.com/2013/03/nandos_singapore_ohhhoney.jpg"])]
        
        var place5 = Place()
        place5.name = "Diao Xiao Er"
        place5.tags = ["Chinese", "Restaurant"]
        place5.images = [ImageMeta(images: ["500x385": "https://www.hpility.sg/wp-content/uploads/2012/12/DianXiaoEr01.jpg"])]
        
        return [place1, place2, place3, place4, place5, place1, place2, place3, place4, place5].shuffled()
    }
}

/**
 LocationClient from LocationService in munch-core/munch-api
 that is direct proxy to LocationService in munch-core/service-location
 */
class LocationClient: RestfulClient {
    
    func streetReverse(lat: Double, lng: Double, callback: @escaping (_ meta: MetaJSON, _ location: String?) -> Void) {
        super.get("/locations/streets/reverse", parameters: ["latLng": "\(lat),\(lng)"]) { meta, json in
            callback(meta, json["data"].string)
        }
    }
    
    func suggest(text: String, callback: @escaping (_ meta: MetaJSON, _ locations: [Location]) -> Void) {
        var params = Parameters()
        params["text"] = text
        super.get("/locations/suggest", parameters: params) { meta, json in
            callback(meta, json["data"].map { Location(json: $0.1)! })
        }
    }
}

/**
 CachedSyncClient from CachedSyncService in munch-core/munch-api
 */
class CachedSyncClient: RestfulClient {
    
    func hashes(callback: @escaping (_ meta: MetaJSON, _ hashes: [String: String]) -> Void) {
        super.get("/cached/hashes") { meta, json in
            var hashes = [String: String]()
            for hash in json["data"] {
                hashes[hash.0] = hash.1.stringValue
            }
            callback(meta, hashes)
        }
    }
    
    func get(dataKey: String, callback: @escaping (_ meta: MetaJSON, _ hash: String?, _ json: JSON) -> Void) {
        super.get("/cached/data/\(dataKey)") { meta, json in
            let hash = json["data"]["hash"].string
            let data = json["data"]["data"]
            callback(meta, hash, data)
        }
    }
    
}

/**
 MetaClient from MetaService in munch-core/munch-api
 Used for facilitating alpha/beta testing
 */
class MetaClient: RestfulClient {
    
}

