//
// Created by Fuxing Loh on 18/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Moya

private let ISO_DATE_FORMATTER: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-ddTHH:mm:ss"
    return formatter
}()

public extension TargetType {
    var baseURL: URL {
        return URL(string: "https://api.munch.app/v0.12.0")!
    }

    var sampleData: Data {
        fatalError("sampleData has not been implemented")
    }

    var headers: [String: String]? {
        if let latLng = MunchLocation.lastLatLng {
            return [
                "Content-Type": "application/json",
                "User-Local-Time": ISO_DATE_FORMATTER.string(from: Date()),
                "User-Lat-Lng": latLng,
            ]
        } else {
            return [
                "Content-Type": "application/json",
                "User-Local-Time": ISO_DATE_FORMATTER.string(from: Date())
            ]
        }
    }
}