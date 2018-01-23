//
// Created by Fuxing Loh on 20/1/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import MapKit

import SwiftyJSON
import SnapKit
import SwiftRichString
import SafariServices
import TTGTagCollectionView

class PlaceHeaderAboutCard: PlaceTitleCardView {
    override func didLoad(card: PlaceCard) {
        self.title = "About"
    }

    override class var cardId: String? {
        return "header_About_20171112"
    }
}

class PlaceBasicDescriptionCard: PlaceCardView {
    let descriptionLabel = UILabel()

    override func didLoad(card: PlaceCard) {
        self.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)
        }

        descriptionLabel.text = card["description"].string
        descriptionLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
        descriptionLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        descriptionLabel.numberOfLines = 0
    }

    func countLines(label: UILabel) -> Int {
        self.layoutIfNeeded()
        let myText = label.text! as NSString

        let rect = CGSize(width: label.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let labelSize = myText.boundingRect(with: rect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: label.font], context: nil)

        return Int(ceil(CGFloat(labelSize.height) / label.font.lineHeight))
    }

    override class var cardId: String? {
        return "basic_Description_20171109"
    }
}

class PlaceBasicPhoneCard: PlaceCardView, SFSafariViewControllerDelegate {
    private let phoneTitleLabel = UILabel()
    private let phoneLabel = UILabel()
    private var phone: String?

    override func didLoad(card: PlaceCard) {
        self.selectionStyle = .default
        self.phone = card["phone"].string
        self.addSubview(phoneTitleLabel)
        self.addSubview(phoneLabel)

        phoneTitleLabel.text = "Phone"
        phoneTitleLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .medium)
        phoneTitleLabel.textColor = .black
        phoneTitleLabel.textAlignment = .left
        phoneTitleLabel.numberOfLines = 1
        phoneTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)
            make.width.equalTo(70)
        }

        phoneLabel.attributedText = phone?.set(style: .default { make in
//            make.underline = UnderlineAttribute(color: UIColor.black.withAlphaComponent(0.4), style: NSUnderlineStyle.styleSingle)
            make.font = FontAttribute(font: UIFont.systemFont(ofSize: 15.0, weight: .regular))
            make.color = UIColor.black.withAlphaComponent(0.8)
        })
        phoneLabel.textAlignment = .right
        phoneLabel.numberOfLines = 1
        phoneLabel.snp.makeConstraints { make in
            make.right.equalTo(self).inset(leftRight)
            make.left.equalTo(phoneTitleLabel.snp.right).inset(-10)
            make.top.bottom.equalTo(self).inset(topBottom)
        }
    }

    override func didTap() {
        if let phone = self.phone {
            if let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }

    override class var cardId: String? {
        return "basic_Phone_20171117"
    }
}

class PlaceBasicPriceCard: PlaceCardView {
    private let priceTitleLabel = UILabel()
    private let priceLabel = UILabel()

    override func didLoad(card: PlaceCard) {
        self.addSubview(priceTitleLabel)
        self.addSubview(priceLabel)

        priceTitleLabel.text = "Price"
        priceTitleLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .medium)
        priceTitleLabel.textColor = .black
        priceTitleLabel.textAlignment = .left
        priceTitleLabel.numberOfLines = 1
        priceTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)
            make.width.equalTo(70)
        }

        if let price = card["price"].double {
            priceLabel.text = "~$\(price)/pax"
            priceLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .regular)
            priceLabel.textColor = UIColor.black.withAlphaComponent(0.8)
            priceLabel.textAlignment = .right
            priceLabel.numberOfLines = 1
            priceLabel.snp.makeConstraints { make in
                make.right.equalTo(self).inset(leftRight)
                make.left.equalTo(priceTitleLabel.snp.right).inset(-10)
                make.top.bottom.equalTo(self).inset(topBottom)
            }
        }
    }

    override class var cardId: String? {
        return "basic_Price_20171219"
    }
}

class PlaceBasicWebsiteCard: PlaceCardView, SFSafariViewControllerDelegate {
    private let websiteTitleLabel = UILabel()
    private let websiteLabel = UILabel()
    private var websiteUrl: String?

    override func didLoad(card: PlaceCard) {
        self.selectionStyle = .default
        self.websiteUrl = card["website"].string
        self.addSubview(websiteTitleLabel)
        self.addSubview(websiteLabel)

        websiteTitleLabel.text = "Website"
        websiteTitleLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .medium)
        websiteTitleLabel.textColor = .black
        websiteTitleLabel.textAlignment = .left
        websiteTitleLabel.numberOfLines = 1
        websiteTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)
            make.width.equalTo(70)
        }

        websiteLabel.attributedText = websiteUrl?.set(style: .default { make in
//            make.underline = UnderlineAttribute(color: UIColor.black.withAlphaComponent(0.4), style: NSUnderlineStyle.styleSingle)
            make.font = FontAttribute(font: UIFont.systemFont(ofSize: 15.0, weight: .regular))
            make.color = UIColor.black.withAlphaComponent(0.8)
        })
        websiteLabel.textAlignment = .right
        websiteLabel.numberOfLines = 1
        websiteLabel.snp.makeConstraints { make in
            make.right.equalTo(self).inset(leftRight)
            make.left.equalTo(websiteTitleLabel.snp.right).inset(-10)
            make.top.bottom.equalTo(self).inset(topBottom)
        }
    }

    override func didTap() {
        if let websiteUrl = websiteUrl, let url = URL.init(string: websiteUrl) {
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            controller.present(safari, animated: true, completion: nil)
        }
    }

    override class var cardId: String? {
        return "basic_Website_20171109"
    }
}