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
import Localize_Swift

import SnapKit
import SwiftRichString

import Firebase

class SearchPlaceCard: UITableViewCell, SearchCardView {
    let addButton = PlaceAddButton()
    let topImageView: SizeShimmerImageView = {
        let width = UIScreen.main.bounds.width
        let imageView = SizeShimmerImageView(points: width, height: width)
        imageView.layer.cornerRadius = 3
        return imageView
    }()
    let areaLabel: UIButton = {
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
    fileprivate let bottomView = SearchPlaceCardBottomView()

    var controller: SearchController!
    var place: Place?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        let containerView = UIView()
        containerView.addSubview(topImageView)
        containerView.addSubview(areaLabel)
        containerView.addSubview(bottomView)
        containerView.addSubview(addButton)
        self.addSubview(containerView)

        areaLabel.addTarget(self, action: #selector(onAreaApply(_:)), for: .touchUpInside)
        areaLabel.snp.makeConstraints { make in
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

        addButton.snp.makeConstraints { make in
            make.right.top.equalTo(topImageView).inset(10)
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
        self.addButton.controller = controller

        if let place = card.decode(name: "place", Place.self) {
            self.place = place

            addButton.place = place
            topImageView.render(image: place.images.get(0))
            render(areas: place.areas)
            bottomView.render(place: place)
        }
    }

    private func render(areas: [Area]) {
        if controller.searchQuery.filter.area?.type == .Cluster {
            areaLabel.isHidden = true
            return
        }

        for area in areas {
            if area.type == .Cluster {
                areaLabel.setTitle(area.name, for: .normal)
                areaLabel.isHidden = false
                return
            }
        }
        areaLabel.isHidden = true
    }

    @objc func onAreaApply(_ sender: Any) {
        if let area = self.place?.areas.get(0) {
            self.controller.search { query in
                query.filter.area = area
            }
        }
    }

    static var cardId: String {
        return "basic_Place_20171211"
    }
}

class SearchSmallPlaceCard: UITableViewCell, SearchCardView {
    fileprivate let bottomView = SearchPlaceCardBottomView()

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
        if let place = card.decode(name: "place", Place.self) {
            bottomView.render(place: place)
        }
    }

    static var cardId: String {
        return "basic_SmallPlace_20180129"
    }
}

fileprivate class SearchPlaceCardBottomView: UIView {
    let nameLabel = UILabel()
    let tagView = MunchTagView(count: 4)
    let locationLabel = UILabel()

    private var tagLabelWidth: Constraint!

    static let periodText = " • ".set(style: Style {
        $0.font = UIFont.systemFont(ofSize: 15, weight: .ultraLight)
    })
    static let closingSoonText = "Closing Soon".localized().set(style: Style {
        $0.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        $0.color = UIColor.primary500
    })
    static let closedNowText = "Closed Now".localized().set(style: Style {
        $0.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        $0.color = UIColor.primary500
    })
    static let openingSoonText = "Opening Soon".localized().set(style: Style {
        $0.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        $0.color = UIColor.secondary500
    })
    static let openNowText = "Open Now".localized().set(style: Style {
        $0.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        $0.color = UIColor.secondary500
    })

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

    func render(place: Place) {
        nameLabel.text = place.name
        render(tag: place)
        render(location: place)
    }

    private func render(tag place: Place) {
        self.tagView.removeAll()

        // Render price as first tag
        if let price = place.price?.perPax {
            self.tagView.add(text: "~$\(price)", config: PriceTagViewConfig())
        }

        // Count is Controlled by View
        for tag in place.tags.prefix(3) {
            self.tagView.add(text: tag.name)
        }
    }

    private func render(location place: Place) {
        let line = NSMutableAttributedString()

        if let latLng = place.location.latLng, let distance = MunchLocation.distance(asMetric: latLng) {
            line.append(NSAttributedString(string: "\(distance) - "))
        }

        if let neighbourhood = place.location.neighbourhood {
            line.append(NSAttributedString(string: neighbourhood))
        } else {
            line.append(NSAttributedString(string: "Singapore"))
        }

        // Open Now
        switch place.hours.isOpen() {
        case .opening:
            line.append(SearchPlaceCardBottomView.periodText)
            line.append(SearchPlaceCardBottomView.openingSoonText)
        case .open:
            line.append(SearchPlaceCardBottomView.periodText)
            line.append(SearchPlaceCardBottomView.openNowText)
        case .closed:
            line.append(SearchPlaceCardBottomView.periodText)
            line.append(SearchPlaceCardBottomView.closedNowText)
        case .closing:
            line.append(SearchPlaceCardBottomView.periodText)
            line.append(SearchPlaceCardBottomView.closingSoonText)
        case .none:
            break
        }
        self.locationLabel.attributedText = line
    }
}