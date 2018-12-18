//
//  DiscoverCards.swift
//  Munch
//
//  Created by Fuxing Loh on 13/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import Localize_Swift

import SnapKit
import SwiftyJSON

import Shimmer
import NVActivityIndicatorView

class SearchShimmerPlaceCard: SearchCardView {

    let topView = ShimmerView()
    let bottomView = BottomView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        let containerView = UIView()
        containerView.addSubview(topView)
        containerView.addSubview(bottomView)
        self.addSubview(containerView)

        topView.snp.makeConstraints { make in
            make.left.right.top.equalTo(containerView).priority(999)
            make.bottom.equalTo(bottomView.snp.top).priority(999)
        }

        bottomView.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(containerView).priority(999)
            make.height.equalTo(73).priority(999)
        }

        containerView.snp.makeConstraints { make in
            let height = (UIScreen.main.bounds.width * 0.888) - (topBottom * 2)
            make.height.equalTo(height).priority(999)
            make.left.right.equalTo(self).inset(leftRight).priority(999)
            make.top.bottom.equalTo(self).inset(topBottom).priority(999)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class BottomView: UIView {
        let nameLabel = ShimmerView()
        let tagLabel = ShimmerView()
        let locationLabel = ShimmerView()

        override init(frame: CGRect = CGRect()) {
            super.init(frame: frame)
            self.addSubview(nameLabel)
            self.addSubview(tagLabel)
            self.addSubview(locationLabel)

            nameLabel.isShimmering = false
            nameLabel.snp.makeConstraints { make in
                make.height.equalTo(18)
                make.width.equalTo(200)
                make.left.equalTo(self)
                make.bottom.equalTo(tagLabel.snp.top).inset(-7)
            }

            tagLabel.isShimmering = false
            tagLabel.snp.makeConstraints { make in
                make.height.equalTo(15)
                make.width.equalTo(160)
                make.left.equalTo(self)
                make.bottom.equalTo(locationLabel.snp.top).inset(-7)
            }

            locationLabel.isShimmering = false
            locationLabel.snp.makeConstraints { make in
                make.height.equalTo(15)
                make.width.equalTo(265)
                make.left.equalTo(self)
                make.bottom.equalTo(self)
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    override class var cardId: String {
        return "shimmer_DiscoverShimmerPlaceCard"
    }
}

class SearchStaticNoResultCard: SearchCardView {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        let label = UILabel()
        label.text = "No Result".localized()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.regular)
        self.addSubview(label)

        label.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)

            make.height.equalTo(40)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override class var cardId: String {
        return "static_SearchStaticNoResultCard"
    }
}

class SearchStaticErrorCard: SearchCardView {
    private static let titleFont = FontStyle.h2.font
    private static let messageFont = FontStyle.regular.font

    private let titleImage = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = UIButton()

    override func didLoad(card: SearchCard) {
        self.addSubview(titleImage)
        self.addSubview(titleLabel)
        self.addSubview(descriptionLabel)

        titleLabel.font = SearchStaticErrorCard.titleFont
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.72)
        titleLabel.numberOfLines = 0
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(topBottom)
        }

        descriptionLabel.font = SearchStaticErrorCard.messageFont
        descriptionLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(titleLabel.snp.bottom).inset(-20)
            make.bottom.equalTo(self).inset(24)
        }
    }

    override func willDisplay(card: SearchCard) {
        self.titleLabel.text = card.string(name: "title")
        self.descriptionLabel.text = card.string(name: "message")
    }

    override class func height(card: SearchCard) -> CGFloat {
        var height: CGFloat = topBottom + 20 + 24

        if let title = card.string(name: "title") {
            height += UILabel.textHeight(withWidth: contentWidth, font: titleFont, text: title)
        }

        if let message = card.string(name: "message") {
            height += UILabel.textHeight(withWidth: contentWidth, font: messageFont, text: message)
        }

        return height
    }

    class func create(title: String, message: String?) -> SearchCard {
        return SearchCard(cardId: self.cardId, dictionary: ["title": title, "message": message as Any])
    }

    class func create(type: ErrorType) -> SearchCard {
        switch type {
        case let .error(error):
            return create(title: "Unknown Error".localized(), message: error.localizedDescription)
        case let .message(header, message):
            return create(title: header, message: message)
        case .unknown:
            return create(title: "Unknown Error".localized(), message: "Unknown Error has occurred.".localized())
        case .location:
            return create(title: "No Location Detected".localized(), message: "Try refreshing or moving to another spot.".localized())
        }
    }

    enum ErrorType {
        case error(Error)
        case message(String, String?)
        case unknown
        case location
    }

    override class var cardId: String {
        return "static_SearchStaticErrorCard"
    }
}

class SearchStaticUnsupportedCard: SearchCardView {
    private let titleImage = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = UIButton()

    override func didLoad(card: SearchCard) {
        self.addSubview(titleImage)
        self.addSubview(titleLabel)
        self.addSubview(descriptionLabel)
        self.addSubview(actionButton)

        titleLabel.text = "Welcome back to Munch!".localized()
        titleLabel.font = UIFont.systemFont(ofSize: 22.0, weight: .semibold)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.72)
        titleLabel.backgroundColor = .white
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(topBottom)
        }

        descriptionLabel.text = "While you were away, we have been working very hard to add more sugar and spice to the app to enhance your food discovery journey! Update Munch now to discover what's delicious!".localized()
        descriptionLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        descriptionLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.backgroundColor = .white
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(titleLabel.snp.bottom).inset(-20)
        }

        actionButton.layer.cornerRadius = 3
        actionButton.backgroundColor = .primary500
        actionButton.setTitle("Update Munch".localized(), for: .normal)
        actionButton.contentEdgeInsets.left = 32
        actionButton.contentEdgeInsets.right = 32
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel!.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        actionButton.snp.makeConstraints { (make) in
            make.left.equalTo(self).inset(leftRight)
            make.top.equalTo(descriptionLabel.snp.bottom).inset(-26)
            make.height.equalTo(48)
            make.bottom.equalTo(self).inset(24)
        }
        actionButton.addTarget(self, action: #selector(onUpdateButton(button:)), for: .touchUpInside)
    }

    @objc func onUpdateButton(button: UIButton) {
        if let reviewURL = URL(string: "itms-apps://itunes.apple.com/us/app/apple-store/id1255436754?mt=8"), UIApplication.shared.canOpenURL(reviewURL) {
            UIApplication.shared.open(reviewURL, options: [:], completionHandler: nil)
        }
    }

    override class var cardId: String {
        return "SearchStaticUnsupportedCard"
    }
}

class SearchStaticLoadingCard: SearchCardView {
    private var indicator = NVActivityIndicatorView(frame: .zero, type: .ballBeat, color: .secondary500)

    override init(style: CellStyle = .default, reuseIdentifier: String? = nil) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(indicator)
        indicator.startAnimating()

        indicator.snp.makeConstraints { maker in
            maker.height.equalTo(40).priority(.high)
            maker.left.right.top.equalTo(self)
            maker.bottom.equalTo(self).inset(48)
        }
    }

    func startAnimating() {
        self.indicator.startAnimating()
    }

    func stopAnimating() {
        self.indicator.stopAnimating()
    }

    override class var cardId: String {
        return "static_SearchStaticLoadingCard"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchStaticTopCard: SearchCardView {
    override func didLoad(card: SearchCard) {
        self.backgroundColor = .clear

        let view = UIView()
        view.backgroundColor = .clear
        self.addSubview(view)
        view.snp.makeConstraints { maker in
            maker.height.equalTo(self.topBottom).priority(999)
            maker.edges.equalTo(self)
        }
    }

    override class var cardId: String {
        return "static_SearchStaticTopCard"
    }
}