//
// Created by Fuxing Loh on 19/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import Kingfisher

class SizeImageView: UIImageView {

    let minWidth, minHeight: Int

    init(minWidth: Int, minHeight: Int, frame: CGRect = .zero) {
        self.minWidth = minWidth
        self.minHeight = minHeight
        super.init(frame: frame)
    }

    func render(named: String) {
        self.image = UIImage(named: named)
    }

    func render(image: Image) {
        render(sizes: image.sizes)
    }

    func render(sizes: [Image.Size]) {
        self.image = nil

        if let size = SizeImageView.find(sizes: sizes, minWidth: minWidth, minHeight: minHeight) {
            render(url: size.url)
        }
    }

    func render(url: String) {
        kf.setImage(with: URL(string: url))
    }

    class func find(sizes: [Image.Size], minWidth: Int, minHeight: Int) -> Image.Size? {
        let sizes = sizes.sorted(by: { s1, s2 in s1.width > s2.width })
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