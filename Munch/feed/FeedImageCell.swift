//
// Created by Fuxing Loh on 2018-12-03.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class FeedCellImage: UICollectionViewCell {
    private let imageView: SizeImageView = {
        let width = (UIScreen.main.bounds.width - 24 - 24 - 16) / 2
        let imageView = SizeImageView(points: width, height: 1)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 3
        return imageView
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)

        self.layer.masksToBounds = true
        self.layer.cornerRadius = 3

        imageView.snp.makeConstraints { maker in
            maker.edges.equalTo(self).priority(999)
        }
    }

    func render(with item: ImageFeedItem) -> FeedCellImage {
        imageView.render(image: item.image)
        return self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class func size(item: ImageFeedItem) -> CGSize {
        if let size = item.image.maxSize {
            return CGSize(width: size.width, height: size.height)
        }
        return CGSize(width: 10000, height: 10000)
    }
}