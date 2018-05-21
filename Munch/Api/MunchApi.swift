//
//  RestfulClient.swift
//  Munch
//
//  Created by Fuxing Loh on 23/3/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import UIKit
import Foundation

import Crashlytics
import SwiftyJSON

import Moya
import Result

class MunchProvider<Target>: MoyaProvider<Target> where Target: Moya.TargetType {
    public final class ErrorIntercept: PluginType {
        public func process(_ result: Result<Moya.Response, MoyaError>, target: TargetType) -> Result<Moya.Response, MoyaError> {
            switch result {
            case .success(let response):
                switch response.statusCode {
                case 200, 204:
                    return result

                case 502, 503:
                    let json = JSON(["meta": ["code": 502, "error": [
                        "type": "ServiceUnavailable",
                        "message": "Server temporary down, try again later."
                    ]]])
                    let response = Response(statusCode: response.statusCode, data: try! json.rawData())
                    return Result.failure(MoyaError.statusCode(response))

                case 301, 410:
                    let json = JSON(["meta": ["code": 410, "error": [
                        "type": "UnsupportedException",
                        "message": "Your application version is not supported. Please update the app."
                    ]]])
                    let response = Response(statusCode: response.statusCode, data: try! json.rawData())
                    return Result.failure(MoyaError.statusCode(response))

                case 500:
                    let json = JSON(["meta": ["code": 410, "error": [
                        "type": "UnknownError",
                        "message": "Unknown Error"
                    ]]])
                    let response = Response(statusCode: response.statusCode, data: try! json.rawData())
                    return Result.failure(MoyaError.statusCode(response))

                default:
                    if let error = response.error {
                        return Result.failure(MoyaError.underlying(error, response))
                    }
                    return result
                }

            default:
                return result
            }
        }
    }

    public final class LoggingPlugin: PluginType {
        public func process(_ result: Result<Moya.Response, MoyaError>, target: TargetType) -> Result<Moya.Response, MoyaError> {
            switch result {
            case let .failure(error):
                Crashlytics.sharedInstance().recordError(error)
            default: break
            }
            return result
        }
    }

    public final class func requestMapping(for endpoint: Endpoint, closure: @escaping RequestResultClosure) {
        do {
            var request = try endpoint.urlRequest()
            Authentication.getToken { token in
                if let token = token {
                    request.addValue("Bearer " + token, forHTTPHeaderField: "Authorization")
                }
                closure(.success(request))
            }
        } catch MoyaError.requestMapping(let url) {
            closure(.failure(MoyaError.requestMapping(url)))
        } catch MoyaError.parameterEncoding(let error) {
            closure(.failure(MoyaError.parameterEncoding(error)))
        } catch {
            closure(.failure(MoyaError.underlying(error, nil)))
        }
    }

    public init() {
        super.init(requestClosure: MunchProvider.requestMapping, plugins: [ErrorIntercept(), LoggingPlugin()])
    }
}

struct Meta: Codable {
    var error: Error?

    struct Error: Codable {
        var type: String?
        var message: String?
    }
}

extension Moya.Response {
    func map<D: Decodable>(data type: D.Type, failsOnEmptyData: Bool = true) throws -> D {
        return try map(type, atKeyPath: "data", failsOnEmptyData: failsOnEmptyData)
    }

    var meta: Meta {
        return try! map(Meta.self, atKeyPath: "meta")
    }

    var error: RestfulError? {
        let meta = self.meta
        if let error = meta.error, let type = error.type {
            return RestfulError.type(statusCode, type, error.message)
        }
        return nil
    }
}

extension UIViewController {
    func alert(error moyaError: MoyaError) {
        switch moyaError {
        case let .statusCode(response):
            if let error = response.meta.error {
                alert(error: error, moyaError: moyaError)
                return
            }
        case let .underlying(_, response):
            if let error = response?.meta.error {
                alert(error: error, moyaError: moyaError)
                return
            }
        default: break
        }

        alert(title: "Unhandled Error", message: moyaError.localizedDescription)
    }

    private func alert(error: Meta.Error, moyaError: MoyaError) {
        alert(title: error.type ?? "Unhandled Error", message: error.message ?? moyaError.localizedDescription)
    }
}