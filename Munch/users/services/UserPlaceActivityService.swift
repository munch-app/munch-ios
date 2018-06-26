//
// Created by Fuxing Loh on 18/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

import Moya
import RxSwift
import RealmSwift

import Crashlytics

enum UserPlaceActivityService {
    case put(UserPlaceActivity)
}

extension UserPlaceActivityService: TargetType {
    var path: String {
        switch self {
        case .put(let activity): return "/users/places/activities/\(activity.placeId)/\(activity.startedMillis)"
        }
    }
    var method: Moya.Method {
        return .put
    }
    var task: Task {
        switch self {
        case .put(let activity):
            return .requestJSONEncodable(activity)
        }
    }
}

struct UserPlaceActivity: Codable {
    var placeId: String

    var startedMillis: Int
    var endedMillis: Int?

    var actions: [Action]

    struct Action: Codable {
        var name: String
        var millis: Int
    }
}

class UserPlaceActivityAction: Object {
    @objc dynamic var _placeId: String = ""
    @objc dynamic var _startedMillis: Int = 0
    @objc dynamic var _endedMillis: Int = 0

    @objc dynamic var id: Int = Int(Date().timeIntervalSince1970)
    @objc dynamic var name: String = ""
}

class UserPlaceActivityTracker {
    let placeId: String
    let startedMillis = Int(Date().timeIntervalSince1970)
    let realm = try! Realm()

    init(place: Place) {
        self.placeId = place.placeId
        self.push()
    }

    func end() {
        let endedMillis = Int(Date().timeIntervalSince1970)

        try! realm.write {
            realm.objects(UserPlaceActivityAction.self)
                    .filter("_placeId == '\(placeId)' AND _startedMillis == \(startedMillis)")
                    .forEach { action in
                        action._endedMillis = endedMillis
                    }
        }
    }

    func push() {
        var activityMap = [String: UserPlaceActivity]()

        realm.objects(UserPlaceActivityAction.self).filter("_placeId != '\(placeId)' AND _startedMillis != \(startedMillis)")
                .forEach { actionObject in
                    let mapId = "\(actionObject._placeId)-\(actionObject._startedMillis)"
                    let action = UserPlaceActivity.Action(name: actionObject.name, millis: actionObject.id)

                    // Create/Get Activity
                    var activity = activityMap[mapId] ?? UserPlaceActivity(
                            placeId: actionObject._placeId,
                            startedMillis: actionObject._startedMillis,
                            endedMillis: actionObject._endedMillis != 0 ? actionObject._endedMillis : nil,
                            actions: [])

                    // Append
                    activity.actions = activity.actions + [action]
                    activityMap[mapId] = activity
                }


        let provider = MunchProvider<UserPlaceActivityService>()
        activityMap.forEach { key, value in
            var activity = value
            activity.actions = activity.actions.sorted(by: { a1, a2 in a1.millis < a2.millis })

            provider.rx.request(.put(activity))
                    .subscribe { result in
                        switch result {
                        case .success:
                            try! self.realm.write {
                                let objects = self.realm.objects(UserPlaceActivityAction.self)
                                        .filter("_placeId == '\(activity.placeId)' AND _startedMillis == \(activity.startedMillis)")
                                self.realm.delete(objects)
                            }

                        case .error(let error):
                            print(error)
                            Crashlytics.sharedInstance().recordError(error)
                        }
                    }
        }
    }

    func add(name: String) {
        let objects = realm.objects(UserPlaceActivityAction.self)
                .filter("_placeId == '\(placeId)' AND _startedMillis == \(startedMillis) AND name == '\(name)'")

        // One name per item
        guard objects.isEmpty else {
            return
        }


        try! realm.write {
            let action = UserPlaceActivityAction()
            action._placeId = self.placeId
            action._startedMillis = self.startedMillis
            action._endedMillis = 0
            action.name = name

            realm.add(action)
        }
    }

}