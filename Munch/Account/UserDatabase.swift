//
// Created by Fuxing Loh on 18/1/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Auth0

public class UserDatabase {
    public static var name: String? {
        get {
            return UserDefaults.standard.string(forKey: "user.name")
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: "user.name")
        }
    }

    public static var email: String? {
        get {
            return UserDefaults.standard.string(forKey: "user.email")
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: "user.email")
        }
    }

    public static var pictureUrl: String? {
        get {
            return UserDefaults.standard.string(forKey: "user.pictureUrl")
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: "user.pictureUrl")
        }
    }

    public class func update(userInfo: UserInfo) {
        name = userInfo.name
        email = userInfo.email
        pictureUrl = userInfo.picture?.absoluteString
    }
}