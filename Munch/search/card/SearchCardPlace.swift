//
//  DiscoverBasicCards.swift
//  Munch
//
//  Created by Fuxing Loh on 14/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import Localize_Swift

import SnapKit

class SearchPlaceCard: SearchCardView {
    private let placeCard = PlaceCard()

    override func didLoad(card: SearchCard) {
        self.addSubview(placeCard)
        self.placeCard.controller = self.controller

        placeCard.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.bottom.equalTo(self).inset(topBottom).priority(999)
        }
    }

    override func willDisplay(card: SearchCard) {
        if let place = card.decode(name: "place", Place.self) {
            self.placeCard.place = place
        }
    }

    override func didSelect(card: SearchCard, controller: SearchController) {
        if let place = card.decode(name: "place", Place.self) {
            let controller = RIPController(placeId: place.placeId)
            self.controller.navigationController!.pushViewController(controller, animated: true)
        }
    }

    override class var cardId: String {
        return "Place_2018-12-29"
    }
}