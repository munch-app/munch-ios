//
// Created by Fuxing Loh on 2018-12-03.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class FeedCellImage: UICollectionViewCell {
    private static let font = UIFont.systemFont(ofSize: 11, weight: .semibold)
    private let imageView: SizeImageView = {
        let width = (UIScreen.main.bounds.width - 16 - 16 - 16) / 2
        let imageView = SizeShimmerImageView(points: width, height: 1)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 3
        return imageView
    }()
    private let nameLabel = UILabel()
            .with(font: font)
            .with(color: .ba80)
            .with(numberOfLines: 1)
    private let moreBtn = IconWidget(size: 12, image: UIImage(named: "Navigation_More"), tintColor: .ba75)
    private let controlView = UIControl()
    private var onMoreClosure: (() -> ())?

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)
        self.addSubview(nameLabel)
        self.addSubview(moreBtn)
        self.addSubview(controlView)

        self.layer.masksToBounds = true
        self.layer.cornerRadius = 3

        imageView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        nameLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        imageView.snp.makeConstraints { maker in
            maker.left.right.top.equalTo(self)
            maker.bottom.equalTo(nameLabel.snp.top).inset(-6)
        }

        nameLabel.setContentHuggingPriority(.required, for: .vertical)
        nameLabel.snp.makeConstraints { maker in
            maker.left.equalTo(self)
            maker.bottom.equalTo(self).inset(6)
            maker.right.equalTo(moreBtn.snp.left).inset(-6)
        }

        moreBtn.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(nameLabel)
            maker.right.equalTo(self).inset(2)
        }
        controlView.snp.makeConstraints { maker in
            maker.top.equalTo(imageView.snp.bottom)
            maker.left.right.bottom.equalTo(self)
        }

        controlView.addTarget(self, action: #selector(onMore), for: .touchUpInside)
    }

    func render(with item: FeedItem, places: [Place], onMore: @escaping () -> ()) -> FeedCellImage {
        imageView.render(image: item.image)
        nameLabel.text = places.get(0)?.name
        onMoreClosure = onMore
        return self
    }

    @objc func onMore() {
        self.onMoreClosure?()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static var labelHeight: CGFloat = {
        return UILabel.textHeight(withWidth: 10000, font: font, text: "A")
    }()

    class func size(item: FeedItem) -> CGSize {
        if let size = item.image?.sizes.max {
            return CGSize(width: CGFloat(size.width), height: CGFloat(size.height) + labelHeight + 6 + 6)
        }
        return CGSize(width: 10000, height: 10000 + labelHeight)
    }
}