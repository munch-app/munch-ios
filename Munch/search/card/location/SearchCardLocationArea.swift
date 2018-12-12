//
// Created by Fuxing Loh on 2018-12-12.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class SearchCardLocationArea: SearchCardView {

    private let titleLabel = UILabel()
            .with(style: .h2)
            .with(text: "Discover")
            .with(numberOfLines: 1)

    private let collectionView = SearchCardPlaceCollection()

    private let button = MunchButton(style: .secondaryOutline)
            .with(text: "Show all places in")

    var area: Area?

    override func didLoad(card: SearchCard) {
        self.addSubview(titleLabel)
        self.addSubview(button)
        self.addSubview(collectionView)

        self.collectionView.controller = self.controller

        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(self.leftRight)
            maker.top.equalTo(self).inset(self.topBottom * 2)
        }

        button.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(self.leftRight)
            maker.bottom.equalTo(self).inset(self.topBottom)
        }

        collectionView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(titleLabel.snp.bottom).inset(-24)
            make.bottom.equalTo(button.snp.top).inset(-24)
        }

        button.addTarget(self, action: #selector(onSelectArea), for: .touchUpInside)
    }

    override func willDisplay(card: SearchCard) {
        guard let area = card.decode(name: "area", Area.self) else {
            return
        }

        guard let places = card.decode(name: "places", [Place].self) else {
            return
        }

        self.area = area

        titleLabel.with(text: "Discover \(area.name)")
        button.with(text: "Show all places in \(area.name)")

        self.collectionView.places = places
        self.collectionView.reloadData()
        self.collectionView.setContentOffset(.zero, animated: false)
    }

    @objc func onSelectArea() {
        guard let area = self.area else {
            return
        }

        var query = SearchQuery(feature: .Search)
        query.filter.location.type = .Where
        query.filter.location.areas = [area]
        self.controller.push(searchQuery: query)
    }

    override static var cardId: String {
        return "LocationArea_2018-12-10"
    }
}

