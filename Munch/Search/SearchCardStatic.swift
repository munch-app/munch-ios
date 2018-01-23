//
//  DiscoverCards.swift
//  Munch
//
//  Created by Fuxing Loh on 13/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import Shimmer
import NVActivityIndicatorView
import SnapKit
import SwiftyJSON

class SearchShimmerPlaceCard: UITableViewCell, SearchCardView {

    let topView = ShimmerView(color: UIColor.black.withAlphaComponent(0.12))
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

    func render(card: SearchCard, controller: SearchController) {
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
        label.text = "No Result"
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

    func render(card: SearchCard, controller: SearchController) {
    }

    static var cardId: String {
        return "static_SearchStaticNoResultCard"
    }
}

class SearchStaticErrorCard: UITableViewCell, SearchCardView {
    private let titleImage = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = UIButton()

    private var controller: SearchController!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(titleImage)
        self.addSubview(titleLabel)
        self.addSubview(descriptionLabel)

        titleLabel.text = "Error"
        titleLabel.font = UIFont.systemFont(ofSize: 26.0, weight: .semibold)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.72)
        titleLabel.numberOfLines = 0
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(topBottom)
        }

        descriptionLabel.text = "Unknown Error"
        descriptionLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
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

    func render(card: SearchCard, controller: SearchController) {
        self.controller = controller
        self.titleLabel.text = card["type"].string
        self.descriptionLabel.text = card["message"].string
    }

    class func create(meta: MetaJSON) -> SearchCard {
        if let error = meta.error {
            let json = JSON(["type": error.type, "message": error.message])
            return SearchCard(cardId: self.cardId, json: json)
        }
        return self.card
    }

    static var cardId: String {
        return "static_SearchStaticErrorCard"
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

    func render(card: SearchCard, controller: SearchController) {
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

    func render(card: SearchCard, controller: SearchController) {
    }

    static var cardId: String {
        return "static_SearchStaticEmptyCard"
    }
}

class SearchStaticHeight16Card: UITableViewCell, SearchCardView {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.clear

        let view = UIView()
        self.addSubview(view)
        view.snp.makeConstraints { make in
            make.height.equalTo(16).priority(999)
            make.edges.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, controller: SearchController) {
    }

    static var cardId: String {
        return "static_SearchStaticHeight16Card"
    }
}