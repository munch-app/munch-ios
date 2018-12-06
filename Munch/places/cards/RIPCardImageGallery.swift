//
// Created by Fuxing Loh on 2018-12-06.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class RIPGalleryHeaderCard: RIPCard {
    private let label = UILabel(style: .h2)

    override func didLoad(data: PlaceData!) {
        self.addSubview(label)

        label.with(text: "\(data.place.name) Images")
        label.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(12)
            maker.bottom.equalTo(self).inset(24)
        }
    }

    override class func isAvailable(data: PlaceData) -> Bool {
        return !data.images.isEmpty
    }
}

class RIPGalleryImageCard: UICollectionViewCell {
    private let imageView: SizeImageView = {
        let width = (UIScreen.main.bounds.width - 24 - 24 - 16) / 2
        let imageView = SizeImageView(points: width, height: 1)
        imageView.contentMode = .scaleAspectFill
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

    func render(with image: PlaceImage) -> RIPGalleryImageCard {
        imageView.render(sizes: image.sizes)
        return self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class func size(image: PlaceImage) -> CGSize {
        if let size = image.sizes.max {
            return CGSize(width: size.width, height: size.height)
        }
        return CGSize(width: 10000, height: 10000)
    }
}