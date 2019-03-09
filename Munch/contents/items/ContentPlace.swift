//
// Created by Fuxing Loh on 2019-03-08.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class ContentPlace: UITableViewCell {
    private let placeCard = PlaceCard()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(placeCard) { (maker: ConstraintMaker) -> Void in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(12).priority(.high)
            maker.bottom.equalTo(self).inset(12).priority(.high)
        }
    }

    func render(with item: [String: Any], place: Place?) -> ContentPlace{
        if let place = place {
            placeCard.place = place
            placeCard.isHidden = false
        } else {
            placeCard.isHidden = true
        }
        return self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}