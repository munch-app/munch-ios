//
// Created by Fuxing Loh on 2018-12-12.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class SearchCardCollectionHeader: SearchCardView {

    private let titleLabel = UILabel(style: .h2)
            .with(text: "Popular Places in Singapore")
            .with(numberOfLines: 0)

    private let subLabel = UILabel(style: .h6)
            .with(text: "Where the cool kids and food geeks go.")
            .with(numberOfLines: 0)

    private var subConstraint: Constraint!

    override func didLoad(card: SearchCard) {
        self.addSubview(titleLabel)
        self.addSubview(subLabel)

        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(self.leftRight)
            maker.top.equalTo(self).inset(self.topBottom)
            maker.bottom.equalTo(self).inset(topBottom).priority(.low)
        }

        subLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(self.leftRight)
            maker.top.equalTo(titleLabel.snp.bottom).inset(-4)
            self.subConstraint = maker.bottom.equalTo(self).inset(topBottom).priority(.high).constraint
        }
    }

    override func willDisplay(card: SearchCard) {
        guard let collection: UserPlaceCollection = card.decode(name: "collection", UserPlaceCollection.self) else {
            return
        }

        titleLabel.text = collection.name

        if let description = collection.description {
            subLabel.text = description

            subConstraint.activate()
            subLabel.isHidden = false
        } else {
            subConstraint.deactivate()
            subLabel.isHidden = true
        }
    }

    override class func height(card: SearchCard) -> CGFloat {
        guard let collection: UserPlaceCollection = card.decode(name: "collection", UserPlaceCollection.self) else {
            return 1
        }

        let min = self.topBottom +
                FontStyle.h2.height(text: collection.name, width: self.contentWidth) +
                self.topBottom

        guard let description = collection.description else {
            return min
        }

        return min + 4 + FontStyle.h6.height(text: description, width: self.contentWidth)
    }

    override class var cardId: String {
        return "CollectionHeader_2018-12-11"
    }
}