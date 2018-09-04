//
// Created by Fuxing Loh on 12/11/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import Crashlytics

/**
 Basic and Vendor typed Cards
 Access json through the subscript
 */
struct PlaceCard {
    private static let decoder = JSONDecoder()

    var cardId: String

    private var dictionary: [String: Any]

    init(cardId: String, dictionary: [String: Any] = [:]) {
        self.cardId = cardId
        self.dictionary = dictionary
    }

    init(dictionary: [String: Any]) {
        self.dictionary = dictionary["data"] as? [String: Any] ?? [:]
        self.cardId = dictionary["_cardId"] as! String
    }

    subscript(name: String) -> Any? {
        return dictionary[name]
    }
}

// Helper Method
extension PlaceCard {
    func string(name: String) -> String? {
        return self[name] as? String
    }

    func int(name: String) -> Int? {
        return self[name] as? Int
    }

    func double(name: String) -> Double? {
        return self[name] as? Double
    }

    func decode<T>(name: String, _ type: T.Type) -> T? where T: Decodable {
        do {
            if let dict = self[name] {
                let data = try JSONSerialization.data(withJSONObject: dict)
                return try PlaceCard.decoder.decode(type, from: data)
            }
        } catch {
            print(error)
            Crashlytics.sharedInstance().recordError(error)
        }
        return nil
    }
}

class PlaceCardView: UITableViewCell {
    var controller: PlaceController!

    required init(card: PlaceCard, controller: PlaceController) {
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
    let topBottomLarge: CGFloat = 16.0
    let topSeparator: CGFloat = 15.0

    class var cardId: String? {
        return nil
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
    class func create(controller: PlaceController) -> PlaceCardView {
        return self.init(card: self.card, controller: controller)
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

    required init(card: PlaceCard, controller: PlaceController) {
        super.init(card: card, controller: controller)
        self.addSubview(separatorLine)
        self.addSubview(titleLabel)
        self.addSubview(moreButton)

        separatorLine.backgroundColor = UIColor(hex: "d5d4d8")
        separatorLine.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self).inset(topSeparator)
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }

        titleLabel.font = UIFont.systemFont(ofSize: 19.0, weight: .semibold)
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