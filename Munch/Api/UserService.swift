//
// Created by Fuxing Loh on 19/5/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Moya
import Cache

import Crashlytics

enum UserService {
    case authenticate
    case getProfile
    case getSetting
    case patchSetting(search: UserSetting.Search)
}

// MARK: - UserService Protocol Implementation
extension UserService: TargetType {
    var baseURL: URL {
        return URL(string: MunchClient.url)!
    }
    var path: String {
        switch self {
        case .authenticate:
            return "/users/authenticate"
        case .getProfile:
            return "/users/profile"
        case .getSetting:
            return "/users/setting"
        case .patchSetting:
            return "/users/setting/search"
        }
    }
    var method: Moya.Method {
        switch self {
        case .patchSetting:
            return .patch
        case .getSetting, .getProfile:
            return .get
        case .authenticate:
            return .post
        }
    }
    var task: Task {
        switch self {
        case .authenticate, .getProfile, .getSetting:
            return .requestPlain
        case .patchSetting(let search):
            return .requestJSONEncodable(search)
        }
    }
    var sampleData: Data {
        fatalError("sampleData has not been implemented")
    }
    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
}

struct UserData: Codable {
    var profile: UserProfile
    var setting: UserSetting
}

extension UserProfile {
    static var instance: UserProfile? {
        get {
            if let data = UserDefaults.standard.value(forKey: "UserProfile") as? Data {
                return try? PropertyListDecoder().decode(UserProfile.self, from: data)
            }
            return nil
        }
        set(value) {
            Crashlytics.sharedInstance().setUserIdentifier(value?.userId)
            Crashlytics.sharedInstance().setUserName(value?.name)
            Crashlytics.sharedInstance().setUserEmail(value?.email)

            UserDefaults.standard.set(try? PropertyListEncoder().encode(value), forKey: "UserProfile")
        }
    }
}

struct UserProfile: Codable {
    var userId: String?
    var name: String?
    var email: String?
    var photoUrl: String?
}

extension UserSetting {
    static var instance: UserSetting? {
        get {
            if let data = UserDefaults.standard.value(forKey: "UserSetting") as? Data {
                return try? PropertyListDecoder().decode(UserSetting.self, from: data)
            }
            return nil
        }
        set(value) {
            UserDefaults.standard.set(try? PropertyListEncoder().encode(value), forKey: "UserSetting")
        }
    }
}

struct UserSetting: Codable {
    var mailings: [String: Bool]?
    var search: Search

    public struct Search: Codable {
        var tags: [String]
    }
}