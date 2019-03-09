//
// Created by Fuxing Loh on 2019-03-08.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class ContentImage: UITableViewCell {
    private let contentImage: SizeShimmerImageView = {
        let imageView = SizeShimmerImageView(points: UIScreen.main.bounds.width, height: 1)
        imageView.layer.cornerRadius = 3
        return imageView
    }()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(contentImage) { (maker: ConstraintMaker) -> Void in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(12)
            maker.bottom.equalTo(self).inset(12)
        }
    }

    func render(with item: [String: Any]) -> ContentImage {
        if let bodyImage = (item["body"] as? [String: Any])?["image"], let data = try? JSONSerialization.data(withJSONObject: bodyImage) {
            if let image: Image = try? JSONDecoder().decode(Image.self, from: data) {
                contentImage.render(image: image)

                if let heightMultiplier = image.sizes.max?.heightMultiplier {
                    contentImage.snp.makeConstraints { maker in
                        maker.height.equalTo(contentImage.snp.width).multipliedBy(heightMultiplier).priority(.high)
                    }
                }
            }
        }
        return self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}