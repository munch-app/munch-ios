//
// Created by Fuxing Loh on 18/1/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Auth0
import Crashlytics

public class UserDatabase {
    public static var sub: String? {
        get {
            return UserDefaults.standard.string(forKey: "user.sub")
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: "user.sub")
        }
    }

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

    /**
     Check if the name is nil, if nil means that no user data yet loaded
     */
    public static var isEmpty: Bool {
        return name == nil
    }

    public class func update(userInfo: UserInfo) {
        sub = userInfo.sub
        name = userInfo.name
        email = userInfo.email
        pictureUrl = userInfo.picture?.absoluteString

        Crashlytics.sharedInstance().setUserIdentifier(userInfo.sub)
        Crashlytics.sharedInstance().setUserName(userInfo.name)
        Crashlytics.sharedInstance().setUserEmail(userInfo.email)
    }

    public class func removeAll() {
        self.sub = nil
        self.name = nil
        self.email = nil
        self.pictureUrl = nil
    }
}