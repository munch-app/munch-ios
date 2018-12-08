//
// Created by Fuxing Loh on 2018-12-08.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Moya
import RxSwift

enum UserAuthenticateService {
    case authenticate
    case getCustomToken
}

extension UserAuthenticateService: TargetType {
    var path: String {
        switch self {
        case .authenticate:
            return "/users/authenticate"
        case .getCustomToken:
            return "/users/authenticate/custom/token"
        }
    }
    var method: Moya.Method {
        switch self {
        case .getCustomToken:
            return .get
        case .authenticate:
            return .post
        }
    }
    var task: Task {
        return .requestPlain
    }
}

struct UserData: Codable {
    var profile: UserProfile
    var setting: UserSetting
}