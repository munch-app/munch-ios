//
//  PlaceCardBasic.swift
//  Munch
//
//  Created by Fuxing Loh on 8/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import MapKit

import SwiftyJSON
import SnapKit
import SwiftRichString
import SafariServices
import TTGTagCollectionView

class PlaceBasicImageBannerCard: PlaceCardView {
    private let imageGradientView: UIView = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 64)
        gradientLayer.colors = [UIColor.black.withAlphaComponent(0.5).cgColor, UIColor.clear.cgColor]

        let imageGradientView = UIView()
        imageGradientView.layer.insertSublayer(gradientLayer, at: 0)
        imageGradientView.backgroundColor = UIColor.clear
        return imageGradientView
    }()
    private let sourceTitleView: UIButton = {
        let label = UIButton()
        label.titleLabel?.font = UIFont.systemFont(ofSize: 11.0, weight: .regular)
        label.setTitleColor(.white, for: .normal)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        label.contentEdgeInsets = UIEdgeInsets(topBottom: 3, leftRight: 6)
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 9
        label.isUserInteractionEnabled = false
        return label
    }()
    private let pageTitleView: UIButton = {
        let label = UIButton()
        label.titleLabel?.font = UIFont.systemFont(ofSize: 11.0, weight: .regular)
        label.setTitleColor(.white, for: .normal)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        label.contentEdgeInsets = UIEdgeInsets(topBottom: 3, leftRight: 6)
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 9
        label.isUserInteractionEnabled = false
        return label
    }()
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.38)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        collectionView.register(PlaceBasicImageBannerCardImageCell.self, forCellWithReuseIdentifier: "PlaceBasicImageBannerCardImageCell")
        return collectionView
    }()

    var images = [SourcedImage]()

    override func didLoad(card: PlaceCard) {
        self.addSubview(collectionView)
        self.addSubview(imageGradientView)
        self.addSubview(pageTitleView)
        self.addSubview(sourceTitleView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        collectionView.snp.makeConstraints { make in
            make.height.equalTo(UIScreen.main.bounds.height * 0.38).priority(999)
            make.edges.equalTo(self).inset(UIEdgeInsets(top: 0, left: 0, bottom: topBottom, right: 0))
        }

        imageGradientView.snp.makeConstraints { make in
            make.height.equalTo(64)
            make.top.equalTo(self)
            make.left.equalTo(self)
            make.right.equalTo(self)
        }

        pageTitleView.snp.makeConstraints { make in
            make.width.equalTo(32)
            make.right.equalTo(self.collectionView).inset(leftRight)
            make.bottom.equalTo(self.collectionView).inset(topBottom)
        }

        sourceTitleView.snp.makeConstraints { make in
            make.right.equalTo(pageTitleView.snp.left).inset(-5)
            make.bottom.equalTo(self.collectionView).inset(topBottom)
        }

        self.images = card["images"].map({ SourcedImage(json: $0.1) })
        self.pageTitleView.setTitle("\(self.images.isEmpty ? 0 : 1)/\(self.images.count)", for: .normal)
        self.setSourceId(sourcedImage: self.images.get(0))
    }

    override class var cardId: String? {
        return "basic_ImageBanner_20170915"
    }
}

extension PlaceBasicImageBannerCard: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let image = images[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceBasicImageBannerCardImageCell", for: indexPath) as! PlaceBasicImageBannerCardImageCell
        cell.render(image: image)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let indexPath = self.collectionView.indexPathsForVisibleItems.get(0) {
            self.pageTitleView.setTitle("\(indexPath.row + 1)/\(self.images.count)", for: .normal)
            self.setSourceId(sourcedImage: self.images.get(indexPath.row))
        }
    }

    private func setSourceId(sourcedImage: SourcedImage?) {
        if let sourceName = sourcedImage?.sourceName {
            self.sourceTitleView.setTitle(sourceName, for: .normal)
            self.sourceTitleView.isHidden = false
        } else {
            self.sourceTitleView.isHidden = true
        }
    }
}

fileprivate class PlaceBasicImageBannerCardImageCell: UICollectionViewCell {
    let imageView: ShimmerImageView = {
        return ShimmerImageView()
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    func render(image: SourcedImage) {
        imageView.render(sourcedImage: image)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PlaceBasicNameTagCard: PlaceCardView, TTGTextTagCollectionViewDelegate {
    let nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.font = UIFont.systemFont(ofSize: 26.0, weight: .medium)
        nameLabel.textColor = UIColor.black.withAlphaComponent(0.9)
        nameLabel.numberOfLines = 0
        nameLabel.isUserInteractionEnabled = false
        return nameLabel
    }()
    let tagCollection: TTGTextTagCollectionView = {
        let tagCollection = TTGTextTagCollectionView()
        tagCollection.defaultConfig = DefaultTagConfig()
        tagCollection.horizontalSpacing = 6
        tagCollection.numberOfLines = 0
        tagCollection.alignment = .left
        tagCollection.scrollDirection = .vertical
        tagCollection.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 3, right: 0)
        return tagCollection
    }()

    override func didLoad(card: PlaceCard) {
        self.addSubview(nameLabel)
        self.addSubview(tagCollection)
        self.tagCollection.delegate = self

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(self).inset(topBottom)
            make.left.right.equalTo(self).inset(leftRight)
            make.bottom.equalTo(tagCollection.snp.top)
        }

        tagCollection.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(24).priority(999)
            make.bottom.equalTo(self).inset(topBottom).priority(999)
        }

        self.nameLabel.text = card["name"].string


        let tags = card["tags"].arrayValue.map({ $0.stringValue.capitalized })
        for tag in tags {
            self.tagCollection.addTag(tag, with: DefaultTagConfig())
        }

        tagCollection.needsUpdateConstraints()
        tagCollection.layoutIfNeeded()

        print(self.tagCollection.actualNumberOfLines)
    }

    override func layoutIfNeeded() {
        super.layoutIfNeeded()
    }

    override class var cardId: String? {
        return "basic_NameTag_20170912"
    }

    class DefaultTagConfig: TTGTextTagConfig {
        override init() {
            super.init()

            tagTextFont = UIFont.systemFont(ofSize: 15.0, weight: .regular)
            tagShadowOffset = CGSize.zero
            tagShadowRadius = 0
            tagCornerRadius = 3

            tagBorderWidth = 0
            tagTextColor = UIColor.black.withAlphaComponent(0.88)
            tagBackgroundColor = UIColor(hex: "ebebeb")

            tagSelectedBorderWidth = 0
            tagSelectedTextColor = UIColor.black.withAlphaComponent(0.88)
            tagSelectedBackgroundColor = UIColor(hex: "ebebeb")
            tagSelectedCornerRadius = 3

            tagExtraSpace = CGSize(width: 15, height: 8)
        }
    }

    func textTagCollectionView(_ textTagCollectionView: TTGTextTagCollectionView!, didTapTag tagText: String!, at index: UInt, selected: Bool) {
        if let navigationController = self.controller.navigationController {
            if let searchController = navigationController.viewControllers[navigationController.viewControllers.count - 2] as? SearchController {
                navigationController.popViewController(animated: true)

                // Add Selected as filter
                var searchQuery = searchController.searchQuery
                searchQuery.filter.tag.positives.insert(tagText)
                searchController.render(searchQuery: searchQuery)
            }
        }
    }
}

class PlaceBasicBusinessHourCard: PlaceCardView {
    static let openStyle = Style("open", {
        $0.color = UIColor.secondary
    })
    static let closeStyle = Style("close", {
        $0.color = UIColor.primary
    })

    let grid = UIView()
    let indicator = UIButton()
    let openLabel = UILabel()
    let dayView = DayView()

    var openHeightConstraint: Constraint!
    var dayHeightConstraint: Constraint!

    override func didLoad(card: PlaceCard) {
        self.selectionStyle = .default
        self.addSubview(grid)
        grid.addSubview(indicator)
        grid.addSubview(openLabel)
        grid.addSubview(dayView)

        grid.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)
        }

        indicator.isUserInteractionEnabled = false
        indicator.setImage(UIImage(named: "RIP-Expand"), for: .normal)
        indicator.contentHorizontalAlignment = .right
        indicator.tintColor = .black
        indicator.snp.makeConstraints { make in
            make.right.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)
            make.width.equalTo(25)
        }

        openLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.regular)
        openLabel.numberOfLines = 2
        openLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(grid)
            make.left.equalTo(grid)
            make.right.equalTo(indicator.snp.left)
        }

        let hours = BusinessHour(hours: card["hours"].flatMap({ Place.Hour(json: $0.1) }))
        dayView.render(hours: hours)
        dayView.isHidden = true

        if hours.isOpen() {
            openLabel.attributedText = "Open Now\n".set(style: PlaceBasicBusinessHourCard.openStyle) + hours.today
        } else {
            openLabel.attributedText = "Closed Now\n".set(style: PlaceBasicBusinessHourCard.closeStyle) + hours.today
        }
    }

    override func didTap() {
        dayView.isHidden = !dayView.isHidden
        openLabel.isHidden = !openLabel.isHidden
        indicator.isHidden = !indicator.isHidden

        if (openLabel.isHidden) {
            openLabel.snp.removeConstraints()
            dayView.snp.makeConstraints { (make) in
                make.top.bottom.equalTo(grid)
                make.left.right.equalTo(grid)
                make.height.equalTo(44 * 7).priority(999)
            }
        }

        if (dayView.isHidden) {
            dayView.snp.removeConstraints()
            openLabel.snp.makeConstraints { (make) in
                make.top.bottom.equalTo(grid)
                make.left.equalTo(grid)
                make.right.equalTo(indicator.snp.left)
            }
        }
    }

    override class var cardId: String? {
        return "basic_BusinessHour_20170907"
    }

    class DayView: UIView {
        let dayLabels = [UILabel(), UILabel(), UILabel(), UILabel(), UILabel(), UILabel(), UILabel()]

        override init(frame: CGRect = CGRect.zero) {
            super.init(frame: frame)
            self.clipsToBounds = true

            for (index, label) in dayLabels.enumerated() {
                label.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.regular)
                label.numberOfLines = 2
                self.addSubview(label)

                label.snp.makeConstraints { make in
                    make.left.right.equalTo(self)
                    make.height.equalTo(44).priority(998)

                    if index == 0 {
                        make.top.equalTo(self)
                    } else {
                        make.top.equalTo(dayLabels[index - 1].snp.bottom)
                    }
                }
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func render(hours: BusinessHour) {
            func createLine(day: String, dayText: String) -> NSAttributedString {
                if hours.isToday(day: day) {
                    if hours.isOpen() {
                        return "\(dayText)\n" + hours[day].set(style: PlaceBasicBusinessHourCard.openStyle)
                    } else {
                        return "\(dayText)\n" + hours[day].set(style: PlaceBasicBusinessHourCard.closeStyle)
                    }
                } else {
                    return NSAttributedString(string: "\(dayText)\n\(hours[day])")
                }
            }

            dayLabels[0].attributedText = createLine(day: "mon", dayText: "Monday")
            dayLabels[1].attributedText = createLine(day: "tue", dayText: "Tuesday")
            dayLabels[2].attributedText = createLine(day: "wed", dayText: "Wednesday")
            dayLabels[3].attributedText = createLine(day: "thu", dayText: "Thursday")
            dayLabels[4].attributedText = createLine(day: "fri", dayText: "Friday")
            dayLabels[5].attributedText = createLine(day: "sat", dayText: "Saturday")
            dayLabels[6].attributedText = createLine(day: "sun", dayText: "Sunday")
        }
    }
}


