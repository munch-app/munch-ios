//
// Created by Fuxing Loh on 12/11/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class PlaceCardView: UITableViewCell {
    var controller: PlaceViewController!

    required init(card: PlaceCard, controller: PlaceViewController) {
        super.init(style: .default, reuseIdentifier: nil)
        self.controller = controller
        self.selectionStyle = .none
        self.didLoad(card: card)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func didLoad(card: PlaceCard) {

    }

    func didTap() {

    }

    let leftRight: CGFloat = 24.0
    let topBottom: CGFloat = 8.0

    class var cardId: String? {
        return nil
    }
}

class PlaceTitleCardView: PlaceCardView {
    let separatorLine = UIView()
    let titleLabel = UILabel()
    let moreButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "RIP-More"), for: .normal)
        button.tintColor = .black
        button.isUserInteractionEnabled = false
        button.isHidden = true
        return button
    }()

    var title: String? {
        set(title) {
            titleLabel.text = title
        }
        get {
            return titleLabel.text
        }
    }

    required init(card: PlaceCard, controller: PlaceViewController) {
        super.init(card: card, controller: controller)
        self.addSubview(separatorLine)
        self.addSubview(titleLabel)
        self.addSubview(moreButton)

        separatorLine.backgroundColor = UIColor(hex: "d5d4d8")
        separatorLine.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self).inset(15)
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }

        titleLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .semibold)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.85)
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(separatorLine.snp.bottom).inset(-20)
            make.bottom.equalTo(self).inset(11)
        }

        moreButton.snp.makeConstraints { make in
            make.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(titleLabel)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PlaceCardView {

    /**
     Conveniently create a PlaceCard
     */
    class var card: PlaceCard {
        return PlaceCard(cardId: self.cardId!)
    }

    /**
     Create PlaceCardView from controller
     */
    class func create(controller: PlaceViewController) -> PlaceCardView {
        return self.init(card: self.card, controller: controller)
    }
}