//
// Created by Fuxing Loh on 12/5/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import Localize_Swift

import FirebaseAnalytics
import SnapKit
import SwiftRichString

import SwiftyJSON

class SearchAreaClusterListCard: SearchCardView {
    private let titleLabel = UILabel()
            .with(style: .h2)
            .with(text: "Discover Locations")

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = SearchAreaClusterListCardCell.size
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 18

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(type: SearchAreaClusterListCardCell.self)
        return collectionView
    }()

    private var areas = [Area]()
    private var instanceId: String?

    override func didLoad(card: SearchCard) {
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

    override func willDisplay(card: SearchCard) {
        if self.instanceId == card.instanceId {
            return
        }

        self.instanceId = card.instanceId

        if let areas = card.decode(name: "areas", [Area].self) {
            self.areas = areas
        } else {
            self.areas = []
        }
        self.collectionView.setContentOffset(.zero, animated: false)
        self.collectionView.reloadData()
    }

    override class var cardId: String {
        return "AreaClusterList_2018-06-21"
    }
}

extension SearchAreaClusterListCard: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return areas.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(type: SearchAreaClusterListCardCell.self, for: indexPath)
        cell.render(area: areas[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let area = areas[indexPath.row]

        self.controller.push { query in
            query.filter.location.type = .Where
            query.filter.location.areas = [area]
        }
    }

    fileprivate class SearchAreaClusterListCardCell: UICollectionViewCell {
        static let size = CGSize(width: 120, height: 110)
        let imageView: SizeImageView = {
            let imageView = SizeImageView(points: size)
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

        func render(area: Area) {
            nameLabel.text = area.name
            imageView.render(image: area.images?.get(0))
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

class SearchAreaClusterHeaderCard: SearchCardView {

    private let titleLabel = UILabel(style: .h2)
    private let descriptionLabel = UILabel(style: .regular)
            .with(numberOfLines: 4)

    private let spotLabel = UILabel(style: .h6)
    private let streetLabel = UILabel(style: .regular)

    private let imageBanner: SizeImageView = {
        let imageView = SizeImageView(points: contentWidth, height: 100)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.tintColor = .white
        imageView.layer.cornerRadius = 3
        return imageView
    }()

    override func didLoad(card: SearchCard) {
        self.addSubview(titleLabel)
        self.addSubview(imageBanner)
        self.addSubview(descriptionLabel)
        self.addSubview(streetLabel)
        self.addSubview(spotLabel)

        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(self.leftRight)
            maker.top.equalTo(self).inset(self.topBottom)
        }

        imageBanner.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(self.leftRight)
            maker.top.equalTo(titleLabel.snp.bottom).inset(-16)
            maker.height.equalTo(100).priority(.high)
        }

        descriptionLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(self.leftRight)
            maker.height.lessThanOrEqualTo(77).priority(.high)
            maker.top.equalTo(imageBanner.snp.bottom).inset(-16)
        }

        spotLabel.snp.makeConstraints { maker in
            maker.left.equalTo(self).inset(self.leftRight)
            maker.bottom.equalTo(self).inset(self.topBottom)
            maker.height.equalTo(24).priority(.high)
        }

        streetLabel.snp.makeConstraints { maker in
            maker.left.equalTo(spotLabel.snp.right).inset(-self.leftRight)
            maker.right.equalTo(self).inset(self.leftRight)
            maker.top.bottom.equalTo(spotLabel)
        }
    }

    override func willDisplay(card: SearchCard) {
        guard let area: Area = card.decode(name: "area", Area.self) else {
            return
        }

        imageBanner.render(image: area.images?.get(0))
        titleLabel.text = area.name
        spotLabel.text = "\(area.counts?.total ?? 0) food spots"
        streetLabel.text = area.location?.street ?? area.location?.address ?? area.location?.neighbourhood
        descriptionLabel.text = area.description
    }

    override class func height(card: SearchCard) -> CGFloat {
        guard let area: Area = card.decode(name: "area", Area.self) else {
            return 1
        }

        var min = self.topBottom
                + FontStyle.h2.height(text: area.name, width: self.contentWidth)
                + 16
                + 24
                + self.topBottom

        if let images = area.images, images.isEmpty {
            min = min + 16 + 100
        }

        guard let description = area.description else {
            return min
        }

        var height = FontStyle.regular.height(text: description, width: self.contentWidth)
        height = height < 77 ? height : 77
        return min + 16 + height
    }

    override class var cardId: String {
        return "AreaClusterHeader_2018-06-21"
    }
}