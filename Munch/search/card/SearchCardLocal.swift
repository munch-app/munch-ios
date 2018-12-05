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

class SearchShimmerPlaceCard: UITableViewCell, SearchCardView {

    let topView = ShimmerView(color: UIColor.whisper100)
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

    func render(card: SearchCard, delegate: SearchTableViewDelegate) {
    }

    static var cardId: String {
        return "shimmer_DiscoverShimmerPlaceCard"
    }
}

class SearchStaticNoResultCard: UITableViewCell, SearchCardView {
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

    func render(card: SearchCard, delegate: SearchTableViewDelegate) {
    }

    static var cardId: String {
        return "static_SearchStaticNoResultCard"
    }
}

class SearchStaticErrorCard: UITableViewCell, SearchCardView {
    private static let titleFont = UIFont.systemFont(ofSize: 26.0, weight: .semibold)
    private static let messageFont = UIFont.systemFont(ofSize: 17.0, weight: .regular)

    private let titleImage = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = UIButton()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, delegate: SearchTableViewDelegate) {
        self.titleLabel.text = card.string(name: "title")
        self.descriptionLabel.text = card.string(name: "message")
    }

    static func height(card: SearchCard) -> CGFloat {
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

    static var cardId: String {
        return "static_SearchStaticErrorCard"
    }
}

class SearchStaticUnsupportedCard: UITableViewCell, SearchCardView {
    private let titleImage = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = UIButton()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, delegate: SearchTableViewDelegate) {
    }

    static var cardId: String {
        return "SearchStaticUnsupportedCard"
    }
}

class SearchStaticLoadingCard: UITableViewCell, SearchCardView {
    private var indicator: NVActivityIndicatorView!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: UIScreen.main.bounds.width, height: 50))
        self.indicator = NVActivityIndicatorView(frame: frame, type: .ballBeat, color: .primary700, padding: 10)
        indicator.startAnimating()
        self.addSubview(indicator)

        indicator.snp.makeConstraints { make in
            make.height.equalTo(50)
            make.left.right.top.equalTo(self)
            make.bottom.equalTo(self).inset(10)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, delegate: SearchTableViewDelegate) {
    }

    func startAnimating() {
        self.indicator.startAnimating()
    }

    func stopAnimating() {
        self.indicator.stopAnimating()
    }

    static var cardId: String {
        return "static_SearchStaticLoadingCard"
    }
}

class SearchStaticEmptyCard: UITableViewCell, SearchCardView {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = .white

        let view = UIView()
        self.addSubview(view)
        view.snp.makeConstraints { make in
            make.height.equalTo(1).priority(999)
            make.edges.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, delegate: SearchTableViewDelegate) {
    }

    static var cardId: String {
        return "static_SearchStaticEmptyCard"
    }
}

class SearchStaticTopCard: UITableViewCell, SearchCardView {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = .white

        let view = UIView()
        self.addSubview(view)
        view.snp.makeConstraints { make in
            make.height.equalTo(self.topBottom).priority(999)
            make.edges.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, delegate: SearchTableViewDelegate) {
    }

    static var cardId: String {
        return "static_SearchStaticHeight16Card"
    }
}