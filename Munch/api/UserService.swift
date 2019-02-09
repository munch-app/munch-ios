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
            if let userId = value?.userId {
                MunchAnalytic.setUserId(userId: userId)
            }
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
    static let requirements = [
        Tag(tagId: "abb22d3d-7d23-4677-b4ef-a3e09f2f9ada", name: "Halal", type: .Requirement),
        Tag(tagId: "fdf77b3b-8f90-419f-b711-dd25f97046fe", name: "Vegetarian Options", type: .Requirement),
    ]

    static func allow(place: Place) -> Bool {
        guard let tags = UserSearchPreference.instance?.requirements else {
            return true
        }

        if tags.isEmpty {
            return true
        }

        for item in place.tags {
            if tags.contains(where: { $0.tagId == item.tagId }) {
                return true
            }
        }

        return false
    }

    static func allow(remove tag: Tag) -> Bool {
        guard let tags = UserSearchPreference.instance?.requirements else {
            return true
        }

        if tags.contains(where: { $0.tagId == tag.tagId }) {
            return false
        }

        return true
    }

    static func prompt(tag: Tag) -> Bool {
        guard UserSearchPreference.requirements.contains(where: { $0.tagId == tag.tagId }) else {
            return false
        }

        let count = UserDefaults.standard.integer(forKey: "UserSearchPreference.prompt.\(tag.tagId)") + 1
        UserDefaults.standard.set(count, forKey: "UserSearchPreference.prompt.\(tag.tagId)")

        return count < 2
    }
}