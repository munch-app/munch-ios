//
// Created by Fuxing Loh on 18/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Moya
import SwiftyJSON

import Crashlytics
import Result

private let ISO_DATE_FORMATTER: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    return formatter
}()

private let encoder = JSONEncoder()

public extension TargetType {
    var baseURL: URL {
        return URL(string: "https://api.munch.app/v0.17.0")!
    }

    var sampleData: Data {
        fatalError("sampleData has not been implemented")
    }

    var headers: [String: String]? {
        if let latLng = MunchLocation.lastLatLng {
            return [
                "Content-Type": "application/json",
                "User-Local-Time": ISO_DATE_FORMATTER.string(from: Date()),
                "User-Lat-Lng": latLng,
            ]
        } else {
            return [
                "Content-Type": "application/json",
                "User-Local-Time": ISO_DATE_FORMATTER.string(from: Date())
            ]
        }
    }

    func requestJSONQueryString<T>(_ encodable: T, parameters: [String: Any]) -> Task where T: Encodable {
        let data: Data = try! encoder.encode(encodable)
        return Task.requestCompositeData(bodyData: data, urlParameters: parameters)
    }
}

class MunchProvider<Target>: MoyaProvider<Target> where Target: Moya.TargetType {
    public final class ErrorIntercept: PluginType {
        let data502: Data = {
            return try! JSON(["meta": ["code": 502, "error": [
                "type": "Service Unavailable",
                "message": "Server temporary down, try again later."
            ]]]).rawData()
        }()
        let data410: Data = {
            return try! JSON(["meta": ["code": 410, "error": [
                "type": "App Update Required",
                "message": "Your application version is not supported. Please update the app."
            ]]]).rawData()
        }()
        let data500: Data = {
            return try! JSON(["meta": ["code": 500, "error": [
                "type": "Unknown Error",
                "message": "Try refreshing the page?"
            ]]]).rawData()
        }()


        public func process(_ result: Result<Moya.Response, MoyaError>, target: TargetType) -> Result<Moya.Response, MoyaError> {
            switch result {
            case .success(let response):
                switch response.statusCode {
                case 200, 204:
                    return result

                case 404:
                    return Result.failure(MoyaError.statusCode(response))

                case 502, 503:
                    let response = Response(statusCode: response.statusCode, data: data502)
                    return Result.failure(MoyaError.statusCode(response))

                case 301, 410:
                    let response = Response(statusCode: response.statusCode, data: data410)
                    return Result.failure(MoyaError.statusCode(response))

                default:
                    if let error = response.error {
                        Crashlytics.sharedInstance().recordError(error)
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
        super.init(requestClosure: MunchProvider.requestMapping, plugins: [LoggingPlugin(), ErrorIntercept()])
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
    func mapNext(failsOnEmptyData: Bool = true) throws -> [String: Any]? {
        if let json = try mapJSON(failsOnEmptyData: failsOnEmptyData) as? [String: Any], let next = json["next"] as? [String: Any] {
            return next
        }
        return nil
    }

    func mapNext(atKeyPath keyPath: String, failsOnEmptyData: Bool = true) throws -> Any? {
        return try mapNext(failsOnEmptyData: failsOnEmptyData)?[keyPath]
    }

    func mapJSON(atKeyPath keyPath: String, failsOnEmptyData: Bool = true) throws -> Any? {
        if let json = try mapJSON(failsOnEmptyData: failsOnEmptyData) as? [String: Any], let data = json[keyPath] {
            return data
        }
        return nil
    }

    func mapJSON(atDataKeyPath keyPath: String, failsOnEmptyData: Bool = true) throws -> Any? {
        if let json = try mapJSON(failsOnEmptyData: failsOnEmptyData) as? [String: Any], let data = json["data"] as? [String: Any], let path = data[keyPath] {
            return path
        }
        return nil
    }

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

// MARK: UIViewController Helper Method
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

extension Error {
    var type: String? {
        if let error = self as? MoyaError {
            switch error {
            case let .underlying(_, response):
                if let error = response?.meta.error {
                    return error.type
                }
            default: break
            }
        }

        return nil
    }
}