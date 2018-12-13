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
    case getProfile
    case getSetting
}

extension UserService: TargetType {
    var path: String {
        switch self {
        case .getProfile:
            return "/users/profile"
        case .getSetting:
            return "/users/setting"
        }
    }
    var method: Moya.Method {
        switch self {
        case .getSetting, .getProfile:
            return .get
        }
    }
    var task: Task {
        switch self {
        case .getProfile, .getSetting:
            return .requestPlain
        }
    }
}


enum UserSearchPreferenceService {
    case put(UserSearchPreference)
    case get
}


extension UserSearchPreferenceService: TargetType {
    var path: String {
        return "/users/search/preference"
    }

    var method: Moya.Method {
        switch self {
        case .get:
            return .get
        case .put:
            return .put
        }
    }
    var task: Task {
        switch self {
        case .get:
            return .requestPlain

        case .put(let preference):
            return .requestJSONEncodable(preference)
        }
    }
}


struct UserProfile: Codable {
    var userId: String?
    var name: String?
    var email: String?
    var photoUrl: String?
}

struct UserSetting: Codable {
    var mailings: [String: Bool]?
}

struct UserSearchPreference: Codable {
    var requirements: [Tag]
    var updatedMillis: Int
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

extension UserSearchPreference {
    static let provider = MunchProvider<UserSearchPreferenceService>()
    static var instance: UserSearchPreference? {
        get {
            if let data = UserDefaults.standard.value(forKey: "UserSearchPreference") as? Data {
                return try? PropertyListDecoder().decode(UserSearchPreference.self, from: data)
            }
            return nil
        }
        set(value) {
            UserDefaults.standard.set(try? PropertyListEncoder().encode(value), forKey: "UserSearchPreference")
        }
    }

    static func isSelected(tag: Tag) -> Bool {
        return self.instance?.requirements.contains(where: { $0.tagId == tag.tagId }) ?? false
    }
}

extension UserSearchPreference {
    static func allow(remove tag: Tag, controller: UIViewController) -> Bool {
        guard let tags = UserSearchPreference.instance?.requirements else {
            return true
        }

        if tags.contains(where: { $0.tagId == tag.tagId }) {
            controller.alert(title: "Search Preference", message: "You have set this as a permanent filter from your profile page. Please remove it from your user profile if you wish to discontinue this permanent filter.")
            return false
        }

        return true
    }
}