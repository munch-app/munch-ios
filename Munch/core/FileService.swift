//
// Created by Fuxing Loh on 18/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

struct Image: Codable {
    var imageId: String?
    var sizes: [Size]

    var profile: Profile?
    var source: Source?
    var meta: Meta?

    struct Size: Codable {
        var width: Int
        var height: Int
        var url: String
    }

    struct Profile: Codable {
        var type: String?
        var id: String?
        var name: String?
    }

    struct Source: Codable {
        var domain: String?
        var originUrl: String?
        var pageUrl: String?
        var pageTitle: String?
    }

    struct Meta: Codable {
        var contentType: String?
        var width: Int?
        var height: Int?
        var bytes: Int?
        var createdMillis: Int?
    }
}