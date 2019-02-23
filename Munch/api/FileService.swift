//
// Created by Fuxing Loh on 18/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

struct CreditedImage {
    var sizes: [Image.Size]
    var name: String?
    var link: String?
}

struct Image: Codable {
    var imageId: String?
    var sizes: [Size]

    var profile: Profile?

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
}

extension Array where Element == Image.Size {
    var max: Image.Size? {
        return self.max { lhs, rhs in
            lhs.width < rhs.width
        }
    }
}

extension Image.Size {
    var heightMultiplier: Float {
        return Float(self.height) / Float(self.width)
    }
}