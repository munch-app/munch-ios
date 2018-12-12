//
//  SearchCardInjected.swift
//  Munch
//
//  Created by Fuxing Loh on 20/10/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class SearchHeaderCard: SearchCardView {
    private let titleLabel = UILabel()
            .with(style: .h2)
            .with(numberOfLines: 0)

    override func didLoad(card: SearchCard) {
        self.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(self).inset(topBottom)
            maker.bottom.equalTo(self)
        }
    }

    override func willDisplay(card: SearchCard) {
        self.titleLabel.text = card.string(name: "title")
    }

    override class func height(card: SearchCard) -> CGFloat {
        let min = topBottom + 6
        if let text = card.string(name: "title") {
            return min + UILabel.textHeight(withWidth: width, font: FontStyle.h2.font, text: text)
        }
        return min
    }

    override class var cardId: String {
        return "Header_2018-11-29"
    }
}