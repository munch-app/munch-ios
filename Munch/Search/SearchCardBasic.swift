//
//  DiscoverBasicCards.swift
//  Munch
//
//  Created by Fuxing Loh on 14/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import SwiftyJSON
import SwiftRichString
import TTGTagCollectionView

import Firebase

class SearchPlaceCard: UITableViewCell, SearchCardView {
    let topImageView = ShimmerImageView()
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
    let bottomView = SearchPlaceCardBottomView()

    var controller: SearchController!
    var containers: [Container] = []

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

        topImageView.layer.cornerRadius = 3
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

    func render(card: SearchCard, controller: SearchController) {
        self.controller = controller
        self.containers = card["containers"].map({ Container(json: $0.1) })

        let images = card["images"].flatMap {
            SourcedImage(json: $0.1)
        }

        render(containers: containers)
        topImageView.render(sourcedImage: images.get(0))
        bottomView.render(card: card)

        Analytics.logEvent(AnalyticsEventViewSearchResults, parameters: [
            AnalyticsParameterSearchTerm: "" as NSObject,
        ])
    }

    private func render(containers: [Container]) {
        if controller.searchQuery.filter.containers?.isEmpty ?? true {
            for container in containers {
                if let type = container.type, type.lowercased() != "area", let name = container.name {
                    containerLabel.setTitle(name, for: .normal)
                    containerLabel.isHidden = false
                    return
                }
            }
        }

        containerLabel.isHidden = true
    }

    @objc func onContainerApply(_ sender: Any) {
        if let container = containers.get(0) {
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

class SearchSmallPlaceCard: UITableViewCell, SearchCardView {
    let bottomView = SearchPlaceCardBottomView()

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

    func render(card: SearchCard, controller: SearchController) {
        bottomView.render(card: card)
        setNeedsLayout()
        layoutIfNeeded()
    }

    static var cardId: String {
        return "basic_SmallPlace_20180129"
    }
}

class SearchPlaceCardBottomView: UIView {
    let nameLabel = UILabel()
    let tagCollection = MunchTagCollectionView(showFullyVisibleOnly: true)
    let locationLabel = UILabel()

    private var tagLabelWidth: Constraint!

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.addSubview(nameLabel)
        self.addSubview(tagCollection)
        self.addSubview(locationLabel)

        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        nameLabel.backgroundColor = .white
        nameLabel.snp.makeConstraints { make in
            make.height.equalTo(26)
            make.left.right.equalTo(self)
            make.bottom.equalTo(tagCollection.snp.top)
        }

        tagCollection.isUserInteractionEnabled = false
        tagCollection.snp.makeConstraints { (make) in
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
        var types = [MunchTagCollectionType]()

        if let average = card["review"]["average"].float {
            types.append(.rating(average))
        }

        types.append(contentsOf: card["tags"].prefix(3)
                .flatMap({ $0.1.string?.capitalized })
                .flatMap({ MunchTagCollectionType.tag($0) }))

        self.tagCollection.replaceAll(types: types)
    }

    private func render(location card: SearchCard) {
        let line = NSMutableAttributedString()

        // Neighbourhood
        if let street = card["location"]["neighbourhood"].string {
            line.append(NSMutableAttributedString(string: street))
        } else {
            line.append(NSMutableAttributedString(string: "Singapore"))
        }

        // Distance
        if let latLng = card["location"]["latLng"].string {
            if let distance = MunchLocation.distance(asMetric: latLng) {
                line.append(NSMutableAttributedString(string: " - \(distance)"))
            }
        }

        // Open Now
        let hours = card["hours"].flatMap({ Place.Hour(json: $0.1) })
        switch Place.Hour.Formatter.isOpen(hours: hours) {
        case .opening:
            line.append(NSMutableAttributedString(string: " • ", attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15, weight: .ultraLight)]))
            line.append(NSMutableAttributedString(string: "Opening Soon", attributes: [NSAttributedStringKey.foregroundColor: UIColor.secondary]))
        case .open:
            line.append(NSMutableAttributedString(string: " • ", attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15, weight: .ultraLight)]))
            line.append(NSMutableAttributedString(string: "Open Now", attributes: [NSAttributedStringKey.foregroundColor: UIColor.secondary]))
        case .closed:
            line.append(NSMutableAttributedString(string: " • ", attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15, weight: .ultraLight)]))
            line.append(NSMutableAttributedString(string: "Closed Now", attributes: [NSAttributedStringKey.foregroundColor: UIColor.primary]))
        case .closing:
            line.append(NSMutableAttributedString(string: " • ", attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15, weight: .ultraLight)]))
            line.append(NSMutableAttributedString(string: "Closing Soon", attributes: [NSAttributedStringKey.foregroundColor: UIColor.primary]))
        case .none:
            break
        }
        self.locationLabel.attributedText = line
    }
}