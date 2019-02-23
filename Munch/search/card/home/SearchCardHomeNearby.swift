//
// Created by Fuxing Loh on 2018-12-12.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import RxSwift

class SearchHomeNearbyCard: SearchCardView {
    private let disposeBag = DisposeBag()

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
            .with(text: "Explore places around you")
            .with(color: .white)
            .with(alignment: .center)

    let button = MunchButton(style: .border)
            .with(text: "Discover Nearby")
            .with(color: .secondary700)

    override func didLoad(card: SearchCard) {
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

        imgView.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(self).inset(topBottom)
            maker.bottom.equalTo(self).inset(topBottom)
            maker.height.equalTo(imgView.snp.width).multipliedBy(0.44).priority(.high)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(imgView).inset(24)
            maker.top.equalTo(imgView)
            maker.bottom.equalTo(button.snp.top)
        }

        button.snp.makeConstraints { maker in
            maker.bottom.equalTo(imgView).inset(24)
            maker.centerX.equalTo(imgView)
        }
    }

    override func didSelect(card: SearchCard, controller: SearchController) {
        MunchLocation.request(force: true, permission: true).subscribe { event in
            guard case let .success(ll) = event, let _ = ll else {
                return
            }

            var query = SearchQuery(feature: .Search)
            query.filter.location.type = .Nearby
            self.controller.push(searchQuery: query)
        }.disposed(by: disposeBag)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.imgView.roundCorners(.allCorners, radius: 3)
    }

    override class var cardId: String {
        return "HomeNearby_2018-12-10"
    }
}