//
// Created by Fuxing Loh on 2018-12-07.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

enum UserDefaultsKey: String, CaseIterable {
    case globalResignActiveDate = "global.ResignActiveDate"

    case notifyFeedWelcome = "notify.FeedWelcome"
    case notifyShareFeedbackV1 = "notify.ShareFeedbackV1"

    case countOpenApp = "count.OpenApp"
    case countViewRip = "count.ViewRip"
}

extension UserDefaults {
    class func clear() {
        UserDefaultsKey.allCases.forEach { (v: UserDefaultsKey) in
            UserDefaults.standard.removeObject(forKey: v.rawValue)
        }
    }

    class func notify(key: UserDefaultsKey, closure: () -> ()) {
        if UserDefaults.standard.bool(forKey: key.rawValue) {
            return
        }

        UserDefaults.standard.set(true, forKey: key.rawValue)
        closure()
    }

    class func count(key: UserDefaultsKey) {
        DispatchQueue.main.async {
            let count = UserDefaults.standard.integer(forKey: key.rawValue) + 1
            UserDefaults.standard.set(count, forKey: key.rawValue)
        }
    }

    class func get(count key: UserDefaultsKey) -> Int {
        return UserDefaults.standard.integer(forKey: key.rawValue)
    }
}