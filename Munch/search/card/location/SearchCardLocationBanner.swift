//
// Created by Fuxing Loh on 2018-12-12.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class SearchCardLocationBanner: SearchCardView {

    let title = UILabel()
            .with(style: .h1)
            .with(color: .white)
            .with(numberOfLines: 0)
            .with(text: "Discover by Neighbourhood")

    let subtitle = UILabel()
            .with(style: .h5)
            .with(color: .white)
            .with(numberOfLines: 0)
            .with(text: "Enter a location and we’ll tell you what’s delicious around.")

    let button = MunchButton(style: .border)
            .with(text: "Enter Location")
            .with(color: .secondary700)

    let imgView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Search-Card-Location-Banner")
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .secondary100
        imageView.clipsToBounds = true

        let overlay = UIView()
        overlay.backgroundColor = .ba50
        imageView.addSubview(overlay)

        overlay.snp.makeConstraints { maker in
            maker.edges.equalTo(imageView)
        }
        return imageView
    }()

    override func didLoad(card: SearchCard) {
        self.addSubview(imgView)
        self.addSubview(title)
        self.addSubview(subtitle)
        self.addSubview(button)

        imgView.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.top.equalTo(self).inset(-self.topBottom)
            maker.bottom.equalTo(self).inset(self.topBottom)
            maker.height.equalTo(264).priority(.high)
        }

        title.snp.makeConstraints { maker in
            maker.left.right.equalTo(imgView).inset(24)
            maker.top.equalTo(imgView).inset(24)
        }

        subtitle.snp.makeConstraints { maker in
            maker.left.right.equalTo(imgView).inset(24)
            maker.top.equalTo(title.snp.bottom).inset(-8)
        }

        button.snp.makeConstraints { maker in
            maker.right.bottom.equalTo(imgView).inset(24)
        }

        button.addTarget(self, action: #selector(onEnterLocation), for: .touchUpInside)
    }

    func onEnterLocation() {
        let controller = FilterLocationSearchController(searchQuery: SearchQuery()) { query in
            if let query = query {
                self.controller.push(searchQuery: query)
            }
        }
        self.controller.present(controller, animated: true)
    }

    override class var cardId: String {
        return "LocationBanner_2018-12-10"
    }
}