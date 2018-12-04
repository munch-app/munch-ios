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

class SearchPlaceCard: UITableViewCell, SearchCardView {
    let placeCard = PlaceCard()
    var place: Place!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(placeCard)

        placeCard.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.bottom.equalTo(self).inset(topBottom).priority(999)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, delegate: SearchTableViewDelegate) {
        if let place = card.decode(name: "place", Place.self) {
            self.place = place
            self.placeCard.place = place
        }
    }

    static var cardId: String {
        return "Place_2018-12-29"
    }
}