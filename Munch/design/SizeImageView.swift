//
// Created by Fuxing Loh on 19/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import Kingfisher

class SizeImageView: UIImageView {

    let minWidth, minHeight: Int

    // In Pixels
    init(pixels width: Int, height: Int, frame: CGRect = .zero) {
        self.minWidth = width
        self.minHeight = height

        super.init(frame: frame)
    }

    // In Points
    init(points width: CGFloat, height: CGFloat) {
        let scale = UIScreen.main.scale
        self.minWidth = Int(scale * width)
        self.minHeight = Int(scale * height)
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
    }

    convenience init(points: CGSize) {
        self.init(points: points.width, height: points.height)
    }

    convenience init(pixels: CGSize) {
        self.init(pixels: Int(pixels.width), height: Int(pixels.height))
    }

    func render(named: String) {
        self.image = UIImage(named: named)
    }

    func render(image: Image?) {
        render(sizes: image?.sizes ?? [])
    }

    func render(sizes: [Image.Size]) {
        self.image = nil

        if let size = SizeImageView.find(sizes: sizes, minWidth: minWidth, minHeight: minHeight) {
            render(url: size.url)
        }
    }

    func render(url: String?) {
        self.image = nil

        if let url = url {
            kf.setImage(with: URL(string: url))
        }
    }

    class func find(sizes: [Image.Size], minWidth: Int, minHeight: Int) -> Image.Size? {
        let sizes = sizes.sorted(by: { s1, s2 in s1.width < s2.width })
        for size in sizes {
            if size.width >= minWidth, size.height >= minHeight {
                return size
            }
        }

        if let size = sizes.last {
            return size
        }

        return nil
    }

    class func prefetch(images: [Image], minWidth: Int, minHeight: Int) {
        let images: [URL] = images.compactMap({
            if let size = find(sizes: $0.sizes, minWidth: minWidth, minHeight: minHeight) {
                return URL(string: size.url)
            }
            return nil
        })
        ImagePrefetcher(urls: images).start()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SizeShimmerImageView: SizeImageView {
    private let indicator = ShimmerIndicator()

    override init(pixels width: Int, height: Int, frame: CGRect = .zero) {
        super.init(pixels: width, height: height, frame: frame)

        self.kf.indicatorType = .custom(indicator: indicator)

        self.contentMode = .scaleAspectFill
        self.clipsToBounds = true
        self.backgroundColor = UIColor.black.withAlphaComponent(0.1)
    }

    override init(points width: CGFloat, height: CGFloat) {
        super.init(points: width, height: height)

        self.kf.indicatorType = .custom(indicator: indicator)
        self.contentMode = .scaleAspectFill
        self.clipsToBounds = true
        self.backgroundColor = UIColor.black.withAlphaComponent(0.1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}