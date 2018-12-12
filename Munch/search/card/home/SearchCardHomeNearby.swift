//
// Created by Fuxing Loh on 2018-12-12.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class SearchHomeNearbyCard: SearchCardView {
    let title = UILabel(style: .h2)
            .with(text: "Discover Nearby")

    let imgView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Search-Card-Home-Nearby-Banner")
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .secondary100
        return imageView
    }()

    let titleLabel = UILabel()
            .with(style: .h4)
            .with(numberOfLines: 0)
            .with(text: "Discover Places Near You")
            .with(color: .white)
            .with(alignment: .right)

    let button = MunchButton(style: .border)
            .with(text: "Discover")
            .with(color: .secondary700)

    override func didLoad(card: SearchCard) {
        self.addSubview(title)
        self.addSubview(imgView)
        self.addSubview(titleLabel)
        self.addSubview(button)
        self.button.isUserInteractionEnabled = false

        let overlay = UIView()
        overlay.backgroundColor = .ba40
        imgView.addSubview(overlay)

        overlay.snp.makeConstraints { maker in
            maker.edges.equalTo(imgView)
        }

        title.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(self).inset(topBottom)
        }

        imgView.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(title.snp.bottom).inset(-topBottom)
            maker.bottom.equalTo(self).inset(topBottom)
            maker.height.equalTo(imgView.snp.width).multipliedBy(0.4).priority(.high)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(imgView).inset(24)
            maker.top.equalTo(imgView)
            maker.bottom.equalTo(button.snp.top)
        }

        button.snp.makeConstraints { maker in
            maker.bottom.right.equalTo(imgView).inset(24)
        }
    }

    override func didSelect(card: SearchCard, controller: SearchController) {
        var query = SearchQuery(feature: .Search)
        query.filter.location.type = .Nearby
        self.controller.push(searchQuery: query)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.imgView.roundCorners(.allCorners, radius: 3)
    }

    override class var cardId: String {
        return "HomeNearby_2018-12-10"
    }
}