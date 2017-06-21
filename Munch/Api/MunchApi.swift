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
    
    private let url: String
    
    init(_ url: String) {
        self.url = url
    }
    
    /**
     Params Encoding is query string
     */
    func get(_ path: String, parameters: Parameters = [:], callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        request(method: .get, path: path, encoding: URLEncoding.default, callback: callback)
    }
    
    /**
     Params Encoding is json
     */
    func post(_ path: String, parameters: Parameters = [:], callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        request(method: .post, path: path, encoding: JSONEncoding.default, callback: callback)
    }
    
    /**
     method: HttpMethod
     path: After domain
     paramters: json or query string both supported
     encoding: encoding of paramters
     callback: Meta and Json
     */
    private func request(method: HTTPMethod, path: String, parameters: Parameters = [:], encoding: ParameterEncoding, callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        Alamofire.request(url + path, method: method, parameters: parameters, encoding: encoding)
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

class MunchClient: RestfulClient {
    static let instance = MunchClient()
    
    static let baseUrl = "http://192.168.1.197:8800/v1"
//    static let baseUrl = "http://10.0.1.8:8800/v1"
    
    let places = PlaceClient(baseUrl)
    
    init() {
        super.init(MunchClient.baseUrl)
    }
}

/**
 PlaceClient from PlaceService in munch-core/munch-api
 */
class PlaceClient: RestfulClient {
    
    func categorize(query: SearchQuery, callback: @escaping (_ meta: MetaJSON, _ collections: [PlaceCollection]) -> Void) {
        super.post("/places/categorize", parameters: query.toParams()) { meta, json in
            callback(meta, json["data"].map({PlaceCollection(json: $0.1)}))
        }
    }
    
    func suggest(text: String, size: Int, latLng: String?, callback: @escaping (_ meta: MetaJSON, _ places: [Place]) -> Void) {
        var params = Parameters()
        params["text"] = text
        params["size"] = size
        if let latLng = latLng { params["latLng"] = latLng }
        
        super.post("/places/suggest", parameters: params) { meta, json in
            callback(meta, json["data"].map({Place(json: $0.1)}))
        }
    }
    
    func search(query: SearchQuery, callback: @escaping (_ meta: MetaJSON, _ places: [Place]) -> Void) {
        super.post("/places/search", parameters: query.toParams()) { meta, json in
            callback(meta, json["data"].map({Place(json: $0.1)}))
        }
    }
    
    func get(id: String, callback: @escaping (_ meta: MetaJSON, _ place: Place) -> Void) {
        super.get("/places/\(id)") { meta, json in
            callback(meta, Place(json: json["data"]))
        }
    }
    
    func gallery(id: String, callback: @escaping (_ meta: MetaJSON, _ medias: [Media]) -> Void) {
        super.get("/places/\(id)/gallery/list") { meta, json in
            callback(meta, json["data"].map({Media(json: $0.1)}))
        }
    }
    
    func articles(id: String, callback: @escaping (_ meta: MetaJSON, _ articles: [Article]) -> Void) {
        super.get("/places/\(id)/articles/list") { meta, json in
            callback(meta, json["data"].map({Article(json: $0.1)}))
        }
    }
}

/**
 LocationClient from LocationService in munch-core/munch-api
 that is direct proxy to LocationService in munch-core/service-location
 */
class LocationClient: RestfulClient {
    
    func reverse(lat: Double, lng: Double, callback: @escaping (_ meta: MetaJSON, _ location: Location?) -> Void) {
        var params = Parameters()
        params["lat"] = lat
        params["lng"] = lng
        super.get("/location/reverse", parameters: params) { meta, json in
            callback(meta, json["data"].exists() ? Location(json: json["data"]) : nil)
        }
    }
    
    func search(text: String, callback: @escaping (_ meta: MetaJSON, _ locations: [Location]) -> Void) {
        var params = Parameters()
        params["text"] = text
        super.get("/location/search", parameters: params) { meta, json in
            callback(meta, json["data"].map({Location(json: $0.1)}))
        }
    }
    
    func geocode(text: String, callback: @escaping (_ meta: MetaJSON, _ location: Location?) -> Void) {
        var params = Parameters()
        params["text"] = text
        super.get("/location/geocode", parameters: params) { meta, json in
            callback(meta, json["data"].exists() ? Location(json: json["data"]) : nil)
        }
    }
}

/**
 MetaClient from MetaService in munch-core/munch-api
 Used for facilitating alpha/beta testing
 *
class MetaClient: RestfulClient {
    
}
