//
// Created by Fuxing Loh on 2019-03-12.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import Moya

enum VoucherService {
    case get(String)
    case claim(String, String)
}

extension VoucherService: TargetType {
    var path: String {
        switch self {
        case let .get(voucherId):
            return "/vouchers/\(voucherId)"

        case let .claim(voucherId, _):
            return "/vouchers/\(voucherId)/claim"
        }
    }
    var method: Moya.Method {
        switch self {
        case .get:
            return .get
        case .claim:
            return .post
        }

    }
    var task: Task {
        switch self {
        case .get:
            return .requestPlain
        case let .claim(_, passcode):
            return .requestJSONEncodable(["passcode": passcode])
        }
    }
}

struct Voucher: Codable {
    var voucherId: String

    var image: Image
    var description: String
    var terms: [String]

    var remaining: Int
    var claimed: Bool
}