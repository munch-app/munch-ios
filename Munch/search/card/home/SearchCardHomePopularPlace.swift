//
// Created by Fuxing Loh on 2018-12-12.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class SearchCardHomePopularPlace: SearchCardView {

    private let titleLabel = UILabel(style: .h2)
            .with(text: "Popular Places in Singapore")
            .with(numberOfLines: 0)
    private let subLabel = UILabel(style: .h6)
            .with(text: "Where the cool kids and food geeks go.")
            .with(numberOfLines: 0)

    private let collectionView = SearchCardPlaceCollection()

    private let button = MunchButton(style: .secondaryOutline)
            .with(text: "Show all popular places")

    var collection: UserPlaceCollection?

    override func didLoad(card: SearchCard) {
        self.addSubview(titleLabel)
        self.addSubview(button)
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

        button.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(self.leftRight)
            maker.bottom.equalTo(self).inset(self.topBottom * 2)
        }

        collectionView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(subLabel.snp.bottom).inset(-24)
            make.bottom.equalTo(button.snp.top).inset(-24)
        }

        button.addTarget(self, action: #selector(onSelect), for: .touchUpInside)
    }

    override func willDisplay(card: SearchCard) {
        guard let collection: UserPlaceCollection = card.decode(name: "collection", UserPlaceCollection.self) else {
            return
        }

        guard let places = card.decode(name: "places", [Place].self) else {
            return
        }

        self.collection = collection
        self.collectionView.places = places
        self.collectionView.reloadData()
        self.collectionView.setContentOffset(.zero, animated: false)
    }

    @objc func onSelect() {
        guard let collectionId = self.collection?.collectionId, let name = self.collection?.name else {
            return
        }

        let collection = SearchQuery.Collection(name: name, collectionId: collectionId)
        self.controller.push(searchQuery: SearchQuery(collection: collection))
    }

    override class var cardId: String {
        return "HomePopularPlace_2018-12-10"
    }
}