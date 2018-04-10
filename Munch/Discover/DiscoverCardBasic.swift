//
//  DiscoverBasicCards.swift
//  Munch
//
//  Created by Fuxing Loh on 14/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import os.log

import Foundation
import UIKit

import SnapKit
import SwiftyJSON
import SwiftRichString
import TTGTagCollectionView

import Firebase

class DiscoverPlaceCard: UITableViewCell, SearchCardView {
    static var total: Int = 0
    static var parse: Int = 0
    static var container: Int = 0
    static var image: Int = 0
    static var bottom: Int = 0
    static var totalCount: Int = 0

    let topImageView: ShimmerImageView = {
        let imageView = ShimmerImageView()
        imageView.layer.cornerRadius = 3

        let width = Int(UIScreen.main.bounds.width)
        imageView.imageView.size = (width, width)
        return imageView
    }()
    let containerLabel: UIButton = {
        let label = UIButton()
        for view in label.subviews {
            view.isOpaque = true
            view.backgroundColor = .white
            view.clipsToBounds = true
        }

        label.titleLabel?.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        label.titleLabel?.isOpaque = true
        label.titleLabel?.clipsToBounds = true
        label.titleLabel?.backgroundColor = UIColor(hex: "FAFAFA")
        label.imageView?.isOpaque = true
        label.imageView?.backgroundColor = UIColor(hex: "FAFAFA")

        label.setTitleColor(UIColor(hex: "202020"), for: .normal)
        label.isOpaque = true
        label.backgroundColor = UIColor(hex: "FAFAFA")

        label.contentEdgeInsets.top = 3
        label.contentEdgeInsets.bottom = 3
        label.contentEdgeInsets.left = 10
        label.contentEdgeInsets.right = 8
        label.imageEdgeInsets.left = -8
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 4
        label.isUserInteractionEnabled = true

        label.setImage(UIImage(named: "Search-Container-Small"), for: .normal)
        label.tintColor = UIColor(hex: "202020")
        return label
    }()
    let bottomView = DiscoverPlaceCardBottomView()

    var controller: DiscoverController!
    var containers: [JSON] = []

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        let containerView = UIView()
        containerView.addSubview(topImageView)
        containerView.addSubview(containerLabel)
        containerView.addSubview(bottomView)
        self.addSubview(containerView)

        containerLabel.addTarget(self, action: #selector(onContainerApply(_:)), for: .touchUpInside)
        containerLabel.snp.makeConstraints { make in
            make.left.equalTo(topImageView).inset(8)
            make.bottom.equalTo(topImageView).inset(8)
        }

        topImageView.snp.makeConstraints { make in
            make.left.right.top.equalTo(containerView)
            make.bottom.equalTo(bottomView.snp.top)
        }

        bottomView.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(containerView)
            make.height.equalTo(75).priority(999)
        }

        containerView.snp.makeConstraints { make in
            let height = (UIScreen.main.bounds.width * 0.888) - (topBottom * 2)
            make.height.equalTo(height).priority(999)
            make.left.right.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, controller: DiscoverController) {
        self.controller = controller

        let startDate = Date()
        self.containers = card["containers"].array ?? []

        let parsedDate = Date()
        render(containers: containers)
        let containerDate = Date()

        // Top Image Rendering
        if let images = card.dict(name: "images") as? [[String: Any]], let image = images.get(0) {
            topImageView.render(images: image["images"] as? [String: String])
        } else {
            topImageView.render(images: [:])
        }

        let imageDate = Date()
        bottomView.render(card: card)
        let bottomDate = Date()

        Analytics.logEvent(AnalyticsEventViewSearchResults, parameters: [
            AnalyticsParameterSearchTerm: "" as NSObject,
        ])

        let total = Calendar.micro(from: startDate, to: Date())
        let parse = Calendar.micro(from: startDate, to: parsedDate)
        let container = Calendar.micro(from: parsedDate, to: containerDate)
        let image = Calendar.micro(from: containerDate, to: imageDate)
        let bottom = Calendar.micro(from: imageDate, to: bottomDate)
        os_log("DiscoverPlaceCard finished card:controller: rendering in (micro) total:%lu parse:%lu container:%lu image:%lu bottom:%lu", type: .info,
                total, parse, container, image, bottom)

        DiscoverPlaceCard.total += total
        DiscoverPlaceCard.parse += parse
        DiscoverPlaceCard.container += container
        DiscoverPlaceCard.image += image
        DiscoverPlaceCard.bottom += bottom
        DiscoverPlaceCard.totalCount += 1
        if DiscoverPlaceCard.totalCount % 10 == 0 {
            os_log("DiscoverPlaceCard benchmark for %lu card:controller: rendering in (micro) total:%lu parse:%lu container:%lu image:%lu bottom:%lu", type: .info,
                    DiscoverPlaceCard.totalCount,
                    DiscoverPlaceCard.total / DiscoverPlaceCard.totalCount,
                    DiscoverPlaceCard.parse / DiscoverPlaceCard.totalCount,
                    DiscoverPlaceCard.container / DiscoverPlaceCard.totalCount,
                    DiscoverPlaceCard.image / DiscoverPlaceCard.totalCount,
                    DiscoverPlaceCard.bottom / DiscoverPlaceCard.totalCount)
        }
    }

    private func render(containers: [JSON]) {
        // Container.create(json: $0.1)!
        if controller.searchQuery.filter.containers?.isEmpty ?? true {
            for container in containers {
                if container["type"].string?.lowercased() != "area", let name = container["name"].string {
                    containerLabel.setTitle(name, for: .normal)
                    containerLabel.isHidden = false
                    return
                }
            }
        }

        containerLabel.isHidden = true
    }

    @objc func onContainerApply(_ sender: Any) {
        if let json = containers.get(0), let container = Container.create(json: json) {
            var searchQuery = self.controller.searchQuery
            searchQuery.filter.containers = [container]
            searchQuery.filter.location = nil
            self.controller.render(searchQuery: searchQuery)
        }
    }

    static var cardId: String {
        return "basic_Place_20171211"
    }
}

class DiscoverSmallPlaceCard: UITableViewCell, SearchCardView {
    let bottomView = DiscoverPlaceCardBottomView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(bottomView)

        bottomView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)
            make.height.equalTo(75).priority(999)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, controller: DiscoverController) {
        bottomView.render(card: card)
        setNeedsLayout()
        layoutIfNeeded()
    }

    static var cardId: String {
        return "basic_SmallPlace_20180129"
    }
}

class DiscoverPlaceCardBottomView: UIView {
    let nameLabel = UILabel()
    let tagView = MunchTagView(count: 4)
    let locationLabel = UILabel()

    private var tagLabelWidth: Constraint!

    static let periodText = " • ".set(style: Style("open", {
        $0.font = FontAttribute(font: UIFont.systemFont(ofSize: 15, weight: .ultraLight))
    }))
    static let closingSoonText = "Closing Soon".set(style: Style("open", {
        $0.font = FontAttribute(font: UIFont.systemFont(ofSize: 13, weight: .semibold))
        $0.color = UIColor.primary
    }))
    static let closedNowText = "Closed Now".set(style: Style("open", {
        $0.font = FontAttribute(font: UIFont.systemFont(ofSize: 13, weight: .semibold))
        $0.color = UIColor.primary
    }))
    static let openingSoonText = "Opening Soon".set(style: Style("open", {
        $0.font = FontAttribute(font: UIFont.systemFont(ofSize: 13, weight: .semibold))
        $0.color = UIColor.secondary
    }))
    static let openNowText = "Open Now".set(style: Style("open", {
        $0.font = FontAttribute(font: UIFont.systemFont(ofSize: 13, weight: .semibold))
        $0.color = UIColor.secondary
    }))

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.addSubview(nameLabel)
        self.addSubview(tagView)
        self.addSubview(locationLabel)

        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        nameLabel.backgroundColor = .white
        nameLabel.snp.makeConstraints { make in
            make.height.equalTo(26)
            make.left.right.equalTo(self)
            make.bottom.equalTo(tagView.snp.top)
        }

        tagView.isUserInteractionEnabled = false
        tagView.snp.makeConstraints { (make) in
            make.left.equalTo(self)
            make.right.equalTo(self)
            make.height.equalTo(24)
            make.bottom.equalTo(locationLabel.snp.top)
        }

        locationLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        locationLabel.textColor = UIColor.black.withAlphaComponent(0.75)
        locationLabel.backgroundColor = .white
        locationLabel.snp.makeConstraints { make in
            make.height.equalTo(19)
            make.left.right.equalTo(self)
            make.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard) {
        nameLabel.text = card["name"].string
        render(tag: card)
        render(location: card)
    }

    private func render(tag card: SearchCard) {
        // Count is Controlled by View
        self.tagView.removeAll()

        if let average = card["review"]["average"].float {
            let percent = CGFloat(average)
            let text = ReviewRatingUtils.text(percent: percent)
            self.tagView.add(text: text, config: RatingTagViewConfig(percent: percent))
        }

        for tag in card["tags"].prefix(3) {
            if let text = tag.1.string?.capitalized {
                self.tagView.add(text: text)
            }
        }
    }

    private func render(location card: SearchCard) {
        let line = NSMutableAttributedString()

        // Distance CPU: 0 - 5000 ticks
        if let latLng = card["location"]["latLng"].string {
            if let distance = MunchLocation.distance(asMetric: latLng) {
                line.append(NSAttributedString(string: "\(distance) - "))
            }
        }

        // Neighbourhood
        if let street = card["location"]["neighbourhood"].string {
            line.append(NSAttributedString(string: street))
        } else {
            line.append(NSAttributedString(string: "Singapore"))
        }

        // Open Now
        switch Place.Hour.Formatter.isOpen(hours: card["hours"].arrayValue) {
        case .opening:
            line.append(DiscoverPlaceCardBottomView.periodText)
            line.append(DiscoverPlaceCardBottomView.openingSoonText)
        case .open:
            line.append(DiscoverPlaceCardBottomView.periodText)
            line.append(DiscoverPlaceCardBottomView.openNowText)
        case .closed:
            line.append(DiscoverPlaceCardBottomView.periodText)
            line.append(DiscoverPlaceCardBottomView.closedNowText)
        case .closing:
            line.append(DiscoverPlaceCardBottomView.periodText)
            line.append(DiscoverPlaceCardBottomView.closingSoonText)
        case .none:
            break
        }
        self.locationLabel.attributedText = line
    }

    struct RatingTagViewConfig: MunchTagViewConfig {
        let font = UIFont.systemFont(ofSize: 13.0, weight: .medium)
        let textColor = UIColor.white
        let backgroundColor: UIColor

        let extra = CGSize(width: 14, height: 8)

        init(percent: CGFloat) {
            self.backgroundColor = ReviewRatingUtils.color(percent: percent)
        }
    }
}