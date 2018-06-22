//
// Created by Fuxing Loh on 20/5/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import UIKit
import Foundation

import Crashlytics
import Alamofire
import SwiftyJSON

let MunchApi = MunchClient()

public class MunchClient {
    public static let url = "https://api.munch.app/v0.11.0"

    let restful = RestfulClient()
    let places = PlaceClient()
    let collections = CollectionClient()
}

public class RestfulClient {
    private let url: String
    private let version: String
    private let build: String

    init(_ url: String = MunchClient.url) {
        self.url = url
        self.version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        self.build = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
    }

    /**
     Params Encoding is query string
     */
    func get(_ path: String, parameters: Parameters = [:], callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        request(method: .get, path: path, parameters: parameters, encoding: URLEncoding.default, callback: callback)
    }

    /**
     Params Encoding is json
     */
    func post(_ path: String, parameters: Parameters = [:], callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        request(method: .post, path: path, parameters: parameters, encoding: JSONEncoding.default, callback: callback)
    }

    /**
     Params Encoding is json
     */
    func put(_ path: String, parameters: Parameters = [:], callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        request(method: .put, path: path, parameters: parameters, encoding: JSONEncoding.default, callback: callback)
    }

    /**
     Params Encoding is json
     */
    func delete(_ path: String, parameters: Parameters = [:], callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        request(method: .delete, path: path, parameters: parameters, encoding: JSONEncoding.default, callback: callback)
    }

    /**
     Params Encoding is json
     */
    func patch(_ path: String, parameters: Parameters = [:], callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        request(method: .patch, path: path, parameters: parameters, encoding: JSONEncoding.default, callback: callback)
    }

    /**
     method: HttpMethod
     path: After domain
     paramters: json or query string both supported
     encoding: encoding of paramters
     callback: Meta and Json
     */
    fileprivate func request(method: Alamofire.HTTPMethod, path: String, parameters: Parameters, encoding: ParameterEncoding, callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        var headers = [String: String]()
        headers["Application-Version"] = version
        headers["Application-Build"] = build

        // Always set latLng if available, only to get from header for logging, debugging purpose only
        // Otherwise, use the explicit value declared
        if let latLng = MunchLocation.lastLatLng {
            headers["Location-LatLng"] = latLng
        }

        Authentication.getToken { token in
            if let token = token {
                headers["Authorization"] = "Bearer \(token)"
            }

            Alamofire.request(self.url + path, method: method, parameters: parameters, encoding: encoding, headers: headers)
                    .responseJSON { response in
                        switch response.result {
                        case .success(let value):
                            let json = JSON(value)
                            let meta = MetaJSON(metaJson: json["meta"])
                            if let error = meta.error?.error {
                                Crashlytics.sharedInstance().recordError(error)
                            }
                            callback(meta, json)
                        case .failure(let error):
                            Crashlytics.sharedInstance().recordError(error)
                            switch response.response?.statusCode ?? 500 {
                            case 502: fallthrough
                            case 503:
                                let json = JSON(["meta": ["code": 502, "error": [
                                    "type": "ServiceUnavailable",
                                    "message": "Server temporary down, try again later."
                                ]]])
                                callback(MetaJSON(metaJson: json["meta"]), json)

                            case 410: fallthrough
                            case 301:
                                let json = JSON(["meta": ["code": 410, "error": [
                                    "type": "UnsupportedException",
                                    "message": "Your application version is not supported. Please update the app."
                                ]]])
                                callback(MetaJSON(metaJson: json["meta"]), json)

                            default:
                                let json = JSON(["meta": ["code": 500, "error": [
                                    "type": "Unknown Error",
                                    "message": error.localizedDescription
                                ]]])
                                callback(MetaJSON(metaJson: json["meta"]), json)
                            }
                        }
                    }

        }
    }
}

public enum RestfulError: Error {
    case type(Int, String, String?)
}

extension RestfulError: CustomNSError, LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .type(_, _, let description):
            return NSLocalizedString(description ?? "Unknown Error", comment: "")
        }
    }

    public var failureReason: String? {
        switch self {
        case .type(_, let type, _):
            return NSLocalizedString(type, comment: "")
        }
    }

    public var errorCode: Int {
        switch self {
        case .type(let code, _, _):
            return code
        }
    }
}

/**
 Meta Json in response
 {meta: {}}
 */
public struct MetaJSON {
    public static let ok = MetaJSON(metaJson: JSON(["code": 200]))

    public static func error(type: String, message: String) -> MetaJSON {
        return MetaJSON(metaJson: JSON(["code": 200, "error": ["type": type, "message": message]]))
    }

    public let code: Int!
    public let error: Error?

    public struct Error {
        public let code: Int
        public let type: String?
        public let message: String?

        public init(code: Int, errorJson: JSON) {
            self.code = code
            self.type = errorJson["type"].string
            self.message = errorJson["message"].string
        }

        public init(code: Int, type: String, message: String) {
            self.code = code
            self.type = type
            self.message = message
        }

        public var error: RestfulError? {
            if let type = self.type {
                return RestfulError.type(code, type, message)
            }
            return nil
        }
    }

    public init(metaJson: JSON) {
        self.code = metaJson["code"].intValue
        if metaJson["error"].exists() {
            self.error = Error(code: code, errorJson: metaJson["error"])
        } else if code == 404 {
            self.error = Error(code: code, type: "Not Found", message: "Resource could not be found.")
        } else {
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
    public func createAlert(type: String = "Unknown Error", message: String = "An unknown error has occurred.") -> UIAlertController {
        let type = error?.type ?? type
        let message = error?.message ?? message
        let alert = UIAlertController(title: type, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        return alert
    }
}