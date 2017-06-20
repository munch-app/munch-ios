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
    
    func get(_ path: String, callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        Alamofire.request(url + path, method: .get).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                callback(MetaJSON(metaJson: json["meta"]), json)
            case .failure(let error):
                print(error)
                // TODO handle timeout
            }
        }
    }
    
    func post(_ path: String, callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        post(path, [:], callback: callback)
    }
    
    func post(_ path: String,_ parameters: Parameters, callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        Alamofire.request(url + path, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    callback(MetaJSON(metaJson: json["meta"]), json)
                case .failure(let error):
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


class PlaceClient: RestfulClient {
    
    func get(id: String, callback: @escaping (_ meta: MetaJSON, _ place: Place) -> Void) {
        super.get("/places/\(id)") { meta, json in
            callback(meta, Place(json: json["data"]))
        }
    }
    
    func gallery(id: String, callback: @escaping (_ meta: MetaJSON, _ medias: [Media]) -> Void) {
        super.get("/places/\(id)/gallery/list") { meta, json in
            callback(meta, json["data"].arrayValue.map({Media(json: $0)}))
        }
    }
    
    func articles(id: String, callback: @escaping (_ meta: MetaJSON, _ articles: [Article]) -> Void) {
        super.get("/places/\(id)/articles/list") { meta, json in
            callback(meta, json["data"].arrayValue.map({Article(json: $0)}))
        }
    }
}
