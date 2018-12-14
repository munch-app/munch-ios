//
// Created by Fuxing Loh on 2018-12-14.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class RIPCardPreference: RIPCard {
    private let label = UILabel()
            .with(style: .h2)
            .with(numberOfLines: 0)
            .with(text: "Tastebud Preference Note")
            .with(color: .error)

    private let sub = UILabel(style: .regular)
            .with(text: "We thought you should know, this place does not fit the requirements of your permanent filter.")
            .with(numberOfLines: 0)

    override func didLoad(data: PlaceData!) {
        self.addSubview(label)
        self.addSubview(sub)

        label.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(12)
        }

        sub.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(label.snp.bottom).inset(-12)
            maker.bottom.equalTo(self).inset(12)
        }
        self.layoutIfNeeded()
    }

    override class func isAvailable(data: PlaceData) -> Bool {
        return !UserSearchPreference.allow(place: data.place)
    }
}