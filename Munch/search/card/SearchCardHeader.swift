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

class SearchHeaderCard: UITableViewCell, SearchCardView {
    private let titleLabel = UILabel()
            .with(style: .h2)
            .with(numberOfLines: 0)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(topBottom)
            make.bottom.equalTo(self).inset(6)
        }
    }

    func render(card: SearchCard, delegate: SearchTableViewDelegate) {
        self.titleLabel.text = card.string(name: "title")
    }

    class func height(card: SearchCard) -> CGFloat {
        let min = topBottom + 6
        if let text = card.string(name: "title") {
            return min + UILabel.textHeight(withWidth: width, font: FontStyle.h2.font, text: text)
        }
        return min
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static var cardId: String {
        return "Header_2018-11-29"
    }
}