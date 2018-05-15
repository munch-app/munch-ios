//
// Created by Fuxing Loh on 12/5/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import MapKit

import FirebaseAnalytics
import SnapKit
import SwiftRichString

import SwiftyJSON

class SearchContainersCard: UITableViewCell, SearchCardView {
    private let titleLabel: SearchHeaderCardLabel = {
        let label = SearchHeaderCardLabel()
        label.text = "Discover Locations"
        return label
    }()
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = CGSize(width: 120, height: 110)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 18

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(SearchContainersCardContainerCell.self, forCellWithReuseIdentifier: "SearchContainersCardContainerCell")
        return collectionView
    }()

    private var controller: DiscoverController!
    private var containers = [Container]()
    private var card: SearchCard?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
//        self.backgroundColor = .bgTag
        self.addSubview(titleLabel)
        self.addSubview(collectionView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(topBottom)
        }

        collectionView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(titleLabel.snp.bottom).inset(-topBottom)
            make.bottom.equalTo(self).inset(topBottom)
            make.height.equalTo(110)
        }
    }

    func render(card: SearchCard, controller: DiscoverController) {
        if self.card?.instanceId == card.instanceId {
            return
        }

        self.controller = controller
        self.card = card

        self.containers = card["containers"].map({ Container.create(json: $0.1)! })
        self.collectionView.setContentOffset(.zero, animated: false)
        self.collectionView.reloadData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static var cardId: String {
        return "injected_Containers_20171211"
    }
}

extension SearchContainersCard: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return containers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let container = containers[indexPath.row]

        Analytics.logEvent(AnalyticsEventViewItem, parameters: [
            AnalyticsParameterItemID: "container-\(container.id ?? "")" as NSObject,
            AnalyticsParameterItemCategory: "discover_containers" as NSObject
        ])

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchContainersCardContainerCell", for: indexPath) as! SearchContainersCardContainerCell
        cell.render(container: container)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let container = containers[indexPath.row]
        var searchQuery = controller.searchQuery
        searchQuery.filter.containers = [container]
        controller.render(searchQuery: searchQuery)

        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
            AnalyticsParameterItemID: "container-\(container.id ?? "")" as NSObject,
            AnalyticsParameterContentType: "discover_containers" as NSObject
        ])
    }

    fileprivate class SearchContainersCardContainerCell: UICollectionViewCell {
        let imageView: MunchImageView = {
            let imageView = MunchImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.backgroundColor = UIColor(hex: "dedede")
            return imageView
        }()

        let nameLabel: UITextView = {
            let nameLabel = UITextView()
            nameLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
            nameLabel.textColor = UIColor.black.withAlphaComponent(0.72)
            nameLabel.backgroundColor = .white

            nameLabel.textContainer.maximumNumberOfLines = 2
            nameLabel.textContainer.lineBreakMode = .byTruncatingTail
            nameLabel.textContainer.lineFragmentPadding = 2
            nameLabel.textContainerInset = UIEdgeInsets(topBottom: 4, leftRight: 4)
            nameLabel.isUserInteractionEnabled = false

//            nameLabel.roundCorners([.bottomLeft, .bottomRight], radius: 3)
            return nameLabel
        }()

        override init(frame: CGRect = .zero) {
            super.init(frame: frame)

            let containerView = UIView()
            containerView.backgroundColor = .clear
            containerView.layer.cornerRadius = 3
            containerView.layer.borderWidth = 1
            containerView.layer.borderColor = UIColor(hex: "DDDDDD").cgColor
            containerView.addSubview(imageView)
            containerView.addSubview(nameLabel)
            self.addSubview(containerView)

            imageView.snp.makeConstraints { make in
                make.left.right.equalTo(containerView)
                make.top.equalTo(containerView)
                make.bottom.equalTo(nameLabel.snp.top)
            }

            nameLabel.snp.makeConstraints { make in
                make.left.right.equalTo(containerView)
                make.bottom.equalTo(containerView)
                make.height.equalTo(40)
            }

            containerView.snp.makeConstraints { make in
                make.edges.equalTo(self)
            }

            self.layoutIfNeeded()
        }

        func render(container: Container) {
            nameLabel.text = container.name
            imageView.render(sourcedImage: container.images?.get(0))
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        fileprivate override func layoutSubviews() {
            super.layoutSubviews()
            self.imageView.roundCorners([.topLeft, .topRight], radius: 3)
        }
    }

}

class SearchContainerHeaderCard: UITableViewCell, SearchCardView {
    static let nameFont = UIFont.systemFont(ofSize: 21.0, weight: .medium)
    static let descriptionFont = UIFont.systemFont(ofSize: 15.0, weight: .regular)
    static let imageSize: CGSize = {
        let imageWidth = width - leftRight - leftRight
        return CGSize(width: imageWidth, height: imageWidth/3.3)
    }()

    private let topImageView: ShimmerImageView = {
        let imageView = ShimmerImageView()
        imageView.tintColor = .white
        imageView.size = imageSize
        imageView.overlay.backgroundColor = UIColor.black.withAlphaComponent(0.33)
        return imageView
    }()
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = nameFont
        label.textColor = UIColor.white
        label.numberOfLines = 0
        return label
    }()
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = descriptionFont
        label.textColor = UIColor(hex: "434343")
        label.numberOfLines = 0
        return label
    }()
    private let addressLineView = AddressLineView()
    private let hourLineView = HourLineView()
    private let grid = UIView()

    private var addressConstraint: Constraint!
    private var hourConstraint: Constraint!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
//        self.backgroundColor = .bgTag

        grid.addSubview(topImageView)
        grid.addSubview(nameLabel)
        grid.addSubview(descriptionLabel)
        grid.addSubview(addressLineView)
        grid.addSubview(hourLineView)
        self.addSubview(grid)

        grid.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)
        }

        topImageView.snp.makeConstraints { make in
            make.top.left.right.equalTo(grid)
            make.height.equalTo(SearchContainerHeaderCard.imageSize.height)
        }

        nameLabel.snp.makeConstraints { make in
            make.left.right.equalTo(topImageView).inset(8)
            make.bottom.equalTo(topImageView).inset(8)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(grid)
            make.top.equalTo(topImageView.snp.bottom).inset(-8)
            self.addressConstraint = make.bottom.equalTo(addressLineView.snp.top).inset(-8).constraint
            self.hourConstraint = make.bottom.equalTo(hourLineView.snp.top).inset(-8).constraint
        }

        self.hourConstraint.deactivate()
        self.addressConstraint.deactivate()

        addressLineView.snp.makeConstraints { make in
            make.left.right.equalTo(grid)
            make.height.equalTo(AddressLineView.height).priority(999)
            make.bottom.equalTo(grid)
        }

        hourLineView.snp.makeConstraints { make in
            make.left.right.equalTo(grid)
            make.height.equalTo(AddressLineView.height).priority(999)
            make.bottom.equalTo(addressLineView.snp.top)
        }
    }

    func render(card: SearchCard, controller: DiscoverController) {
        let images = card["images"].compactMap({ SourcedImage(json: $0.1) })
        topImageView.render(sourcedImage: images.get(0))

        nameLabel.text = card.string(name: "name")
        descriptionLabel.text = card.string(name: "description")

        self.addressConstraint.deactivate()
        self.hourConstraint.deactivate()

        // Address Line
        if let address = card.string(name: "address"), let latLng = card.string(name: "latLng"), let count = card.int(name: "count") {
            self.addressLineView.address = address
            self.addressLineView.latLng = latLng
            self.addressLineView.count = count
            self.addressLineView.isHidden = false
        } else {
            self.addressLineView.isHidden = true
        }

        // Hour Line
        let hours = card["hours"].compactMap({ Place.Hour(json: $0.1) })
        if !hours.isEmpty {
            self.hourLineView.hours = hours
            self.hourLineView.isHidden = false

            self.hourConstraint.activate()
        } else {
            self.hourLineView.isHidden = true
        }

        if !addressLineView.isHidden {
            self.addressConstraint.activate()
        }
        if !hourLineView.isHidden {
            self.hourConstraint.activate()
        }
    }

    static func height(card: SearchCard) -> CGFloat {
        var height: CGFloat = topBottom + topBottom
        let titleWidth = width - (leftRight + leftRight)

        // Image
        height += imageSize.height

        // Description
        if let description = card.string(name: "description") {
            let lines = UILabel.countLines(font: descriptionFont, text: description, width: titleWidth)
            height += CGFloat(lines > 3 ? 3 : lines) * ceil(descriptionFont.lineHeight)
            height += 8
            height += 8
        }

        // Address Line
        if card.string(name: "address") != nil, card.string(name: "latLng") != nil {
            height += AddressLineView.height
        }

        // Hour Line
        if let hours = card["hours"].array, !hours.isEmpty, card["count"].exists() {
            height += AddressLineView.height
        }

        return height
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.topImageView.layer.cornerRadius = 3
    }

    private(set) static var cardId: String = "injected_ContainerHeader_20180511"

    fileprivate class AddressLineView: SRCopyableView {
        static let headerStyle = Style("open", {
            $0.color = UIColor.black
            $0.font = FontAttribute(font: .systemFont(ofSize: 13.0, weight: .medium))
        })
        static let addressStyle = Style("close", {
            $0.color = UIColor.black
            $0.font = FontAttribute(font: .systemFont(ofSize: 15.0, weight: .regular))
        })

        static let countStyle = Style("close", {
            $0.color = UIColor.black
            $0.font = FontAttribute(font: .systemFont(ofSize: 15.0, weight: .regular))
            $0.align = .center
        })
        static let placeStyle = Style("open", {
            $0.color = UIColor.black
            $0.font = FontAttribute(font: .systemFont(ofSize: 13.0, weight: .medium))
            $0.align = .center
        })

        static let height: CGFloat = 52
        static let rightWidth: CGFloat = 60
        private let leftLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 15.0, weight: .regular)
            label.numberOfLines = 0
            return label
        }()
        private let rightLabel: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            label.textAlignment = .center
            return label
        }()

        var address: String! {
            didSet {
                let attributedText = NSMutableAttributedString()
                attributedText.append("Address\n".set(style: AddressLineView.headerStyle))
                attributedText.append(address.set(style: AddressLineView.addressStyle))
                self.leftLabel.attributedText = attributedText
            }
        }
        var count: Int? {
            didSet {
                if let count = self.count {
                    let attributedText = NSMutableAttributedString()
                    attributedText.append("\(count)\n".set(style: AddressLineView.countStyle))
                    attributedText.append("places".set(style: AddressLineView.placeStyle))
                    self.rightLabel.attributedText = attributedText
                } else {
                    self.rightLabel.text = nil
                }
            }
        }
        var latLng: String?

        override var copyableText: String? {
            return self.address
        }

        override init(frame: CGRect = .zero) {
            super.init(frame: frame)
            self.addSubview(leftLabel)
            self.addSubview(rightLabel)

            leftLabel.snp.makeConstraints { make in
                make.left.top.bottom.equalTo(self)
                make.right.equalTo(self.rightLabel.snp.left).inset(-18)
            }

            rightLabel.snp.makeConstraints { make in
                make.right.top.bottom.equalTo(self)
                make.height.equalTo(AddressLineView.height)
                make.width.equalTo(AddressLineView.rightWidth)
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    fileprivate class HourLineView: UIView {
        static let openStyle = Style("open", {
            $0.color = UIColor.secondary
            $0.font = FontAttribute(font: .systemFont(ofSize: 17.0, weight: .semibold))
        })
        static let closeStyle = Style("close", {
            $0.color = UIColor.primary
            $0.font = FontAttribute(font: .systemFont(ofSize: 17.0, weight: .semibold))
        })
        static let hourStyle = Style("hour", {
            $0.color = UIColor.black
            $0.font = FontAttribute(font: .systemFont(ofSize: 14, weight: .regular))
        })
        static let boldStyle = Style("bold", {
            $0.color = UIColor.black
            $0.font = FontAttribute(font: .systemFont(ofSize: 14, weight: .semibold))
        })

        private let leftLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
            label.numberOfLines = 2
            return label
        }()

        var hours: [Place.Hour]? {
            didSet {
                if let hours = self.hours {
                    let hours = BusinessHour(hours: hours)
                    let attributedText = NSMutableAttributedString()
                    switch hours.isOpen() {
                    case .opening:
                        attributedText.append("Opening Soon\n".set(style: PlaceBasicBusinessHourCard.openStyle))
                    case .open:
                        attributedText.append("Open Now\n".set(style: PlaceBasicBusinessHourCard.openStyle))
                    case .closing:
                        attributedText.append("Closing Soon\n".set(style: PlaceBasicBusinessHourCard.closeStyle))
                    case .closed: fallthrough
                    case .none:
                        attributedText.append("Closed Now\n".set(style: PlaceBasicBusinessHourCard.closeStyle))

                    }
                    attributedText.append(hours.today.set(style: PlaceBasicBusinessHourCard.hourStyle))
                    self.leftLabel.attributedText = attributedText
                } else {
                    self.leftLabel.text = nil
                }
            }
        }

        override init(frame: CGRect = .zero) {
            super.init(frame: frame)
            self.addSubview(leftLabel)

            leftLabel.snp.makeConstraints { make in
                make.left.right.top.bottom.equalTo(self)
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}