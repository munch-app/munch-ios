//
// Created by Fuxing Loh on 19/5/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Cache
import Moya
import RxSwift
import Crashlytics

enum UserService {
    case authenticate
    case getProfile
    case getSetting
    case patchSetting(search: UserSetting.Search)
}

// MARK: - UserService Protocol Implementation
extension UserService: TargetType {
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

    /**
     Apply changes to UserSetting, closure will only be called if it exists
     */
    static func apply(search editing: @escaping (UserSetting.Search) -> UserSetting.Search, onComplete: @escaping (SingleEvent<UserSetting>) -> Void) -> Disposable{
        guard var editable = UserSetting.instance else {
            return Disposables.create()
        }
        let changed = editing(editable.search)
        editable.search = changed
        UserSetting.instance = editable

        let provider = MunchProvider<UserService>()
        return provider.rx.request(.patchSetting(search: changed))
                .map { response throws -> UserSetting in
                    try response.map(data: UserSetting.self)
                }
                .subscribe(onComplete)
    }

    static let managed = ["halal", "vegetarian options"]

//    static func request(toPerm searchQuery: SearchQuery) -> String? {
//        for tag in searchQuery.filter.tag.positives {
//            if request(toPerm: tag) {
//                return tag
//            }
//        }
//        return nil
//    }

    static func request(toPerm tag: String) -> Bool {
        let tag = tag.lowercased()
        if let setting = UserSetting.instance {
            if setting.search.tags.contains(tag) {
                return false
            }

            if managed.contains(tag) {
                let count = UserDefaults.standard.integer(forKey: "SearchQueryManager.\(tag)") + 1
                UserDefaults.standard.set(count, forKey: "SearchQueryManager.\(tag)")

                if count == 3 {
                    return true
                }
            }
        }

        return false
    }

    /**
     Check if action is allowed
     */
    static func allow(remove tag: String, controller: UIViewController) -> Bool {
        if let tags = UserSetting.instance?.search.tags {
            if tags.contains(tag.lowercased()) {
                controller.alert(title: "Search Preference", message: "You have set this as a permanent filter from your profile page. Please remove it from your user profile if you wish to discontinue this permanent filter.")
                return false
            }
        }

        return true
    }
}

struct UserSetting: Codable {
    var mailings: [String: Bool]?
    var search: Search

    public struct Search: Codable {
        var tags: [String]
    }
}