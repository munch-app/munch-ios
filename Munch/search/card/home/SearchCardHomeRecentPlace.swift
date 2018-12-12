//
// Created by Fuxing Loh on 2018-12-12.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class SearchCardHomeRecentPlace: SearchCardView {

    private let titleLabel = UILabel(style: .h2)
            .with(text: "Your Recent Places")
            .with(numberOfLines: 0)
    private let subLabel = UILabel(style: .h6)
            .with(text: "Don't worry, we won't tell anybody.")
            .with(numberOfLines: 0)

    private let collectionView = SearchCardPlaceCollection()

    override func didLoad(card: SearchCard) {
        self.addSubview(titleLabel)
        self.addSubview(subLabel)
        self.addSubview(collectionView)

        self.collectionView.controller = self.controller

        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(self.leftRight)
            maker.top.equalTo(self).inset(self.topBottom)
        }

        subLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(self.leftRight)
            maker.top.equalTo(titleLabel.snp.bottom).inset(-4)
        }

        collectionView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(subLabel.snp.bottom).inset(-24)
            make.bottom.equalTo(self).inset(self.topBottom * 2)
        }
    }

    override func willDisplay(card: SearchCard) {
        guard let places = card.decode(name: "places", [Place].self) else {
            return
        }

        self.collectionView.places = places
        self.collectionView.reloadData()
        self.collectionView.setContentOffset(.zero, animated: false)
    }


    override class var cardId: String {
        return "HomeRecentPlace_2018-12-10"
    }
}