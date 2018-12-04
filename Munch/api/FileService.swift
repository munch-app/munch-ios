//
// Created by Fuxing Loh on 18/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//


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

extension Image {
    var maxSize: Size? {
        return self.sizes.max { size, size2 in
            size.width < size2.width
        }
    }
}

extension Image.Size {
    var heightMultiplier: Float {
        return Float(self.height) / Float(self.width)
    }
}