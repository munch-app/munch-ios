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
import SafariServices

import SnapKit
import SwiftyJSON
import SwiftRichString

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

    var images = [Image]()

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

        self.images = card.decode(name: "images", [Image].self) ?? []
        self.pageTitleView.setTitle("\(self.images.isEmpty ? 0 : 1)/\(self.images.count)", for: .normal)
        self.set(profile: self.images.get(0)?.profile)
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
            self.set(profile: self.images.get(indexPath.row)?.profile)
            self.controller.apply(navigation: .bannerImageItem(indexPath.row))
        }
    }

    private func set(profile: Image.Profile?) {
        if let sourceName = profile?.name {
            self.sourceTitleView.setTitle(sourceName, for: .normal)
            self.sourceTitleView.isHidden = false
        } else {
            self.sourceTitleView.isHidden = true
        }
    }
}

fileprivate class PlaceBasicImageBannerCardImageCell: UICollectionViewCell {
    let imageView: SizeShimmerImageView = {
        return SizeShimmerImageView(points: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    func render(image: Image) {
        imageView.render(image: image)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PlaceBasicClosedCard: PlaceCardView {
    private let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22.0, weight: .medium)
        label.text = "Permanently Closed"
        label.textColor = UIColor.white
        label.numberOfLines = 1
        label.isUserInteractionEnabled = false
        return label
    }()

    override func didLoad(card: PlaceCard) {
        backgroundColor = UIColor.primary400
        self.addSubview(label)

        label.snp.makeConstraints { make in
            make.top.bottom.equalTo(self).inset(topBottom + 2)
            make.left.right.equalTo(self).inset(leftRight)
        }
    }

    override class var cardId: String? {
        return "basic_Closed_20180311"
    }
}

class PlaceBasicNameTagCard: PlaceCardView, TTGTextTagCollectionViewDelegate {
    private static let size = CGSize(width: 18, height: 8)
    private static let rightMargin: CGFloat = 16
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
        tagCollection.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        return tagCollection
    }()

    override func didLoad(card: PlaceCard) {
        self.tagCollection.delegate = self
        self.addSubview(nameLabel)

        let collectionHolderView = UIView()
        collectionHolderView.addSubview(tagCollection)
        self.addSubview(collectionHolderView)

        self.nameLabel.text = card.string(name: "name")
        let tags = card.decode(name: "tags", [Tag].self) ?? []
        let tagNames = Array(tags.prefix(6).map({$0.name}))
        self.tagCollection.addTags(tagNames)
        self.tagCollection.reload()

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(self).inset(topBottom)
            make.left.right.equalTo(self).inset(leftRight)
        }

        tagCollection.snp.makeConstraints { (make) in
            make.left.equalTo(collectionHolderView).inset(24)
            make.right.equalTo(collectionHolderView).inset(PlaceBasicNameTagCard.rightMargin)
            make.top.equalTo(collectionHolderView)
        }

        // Collection View is added because of problem with using TTGTextTagCollectionView
        collectionHolderView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(nameLabel.snp.bottom)
            make.bottom.equalTo(self).inset(topBottom)
            make.height.equalTo(self.numberOfLines(tags: tagNames) * 34).priority(999)
        }

        tagCollection.needsUpdateConstraints()
        tagCollection.layoutIfNeeded()
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
            tagBackgroundColor = UIColor.bgTag

            tagSelectedBorderWidth = 0
            tagSelectedTextColor = UIColor.black.withAlphaComponent(0.88)
            tagSelectedBackgroundColor = UIColor.bgTag
            tagSelectedCornerRadius = 3

            tagExtraSpace = PlaceBasicNameTagCard.size
        }
    }

    private func numberOfLines(tags: [String]) -> Int {
        let font = UIFont.systemFont(ofSize: 15.0, weight: .regular)
        let workingWidth = UIScreen.main.bounds.width - leftRight - PlaceBasicNameTagCard.rightMargin

        var lines = 0
        var currentRemaining: CGFloat = 0
        for tag in tags {
            let width = UILabel.textSize(font: font, text: tag, extra: PlaceBasicNameTagCard.size).width
            if currentRemaining - width <= 0 {
                // Not Enough Space, New Line
                lines += 1
                currentRemaining = workingWidth - width - 6
            } else {
                currentRemaining = currentRemaining - width - 6
            }
        }

        if lines == 0 {
            return 1
        }
        return lines
    }

    func textTagCollectionView(_ textTagCollectionView: TTGTextTagCollectionView!, didTapTag tagText: String!, at index: UInt, selected: Bool) {
        if let navigationController = self.controller.navigationController {
            if let searchController = navigationController.viewControllers[navigationController.viewControllers.count - 2] as? SearchController {
                navigationController.popViewController(animated: true)

                // Add Selected as filter
                searchController.search { query in
                    query.filter.tag.positives.insert(tagText)
                }

                self.controller.apply(click: .tag)
            }
        }
    }
}

class PlaceBasicBusinessHourCard: PlaceCardView {
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

        openLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        openLabel.numberOfLines = 2
        openLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(grid)
            make.left.equalTo(grid)
            make.right.equalTo(indicator.snp.left)
        }


        if let hours: [Hour] = card.decode(name: "hours", [Hour].self) {
            let grouped = hours.grouped
            dayView.render(hourGrouped: grouped)
            dayView.isHidden = true

            let attributedText = NSMutableAttributedString()
            switch grouped.isOpen() {
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


            attributedText.append(grouped.todayDayTimeRange.set(style: PlaceBasicBusinessHourCard.hourStyle))
            openLabel.attributedText = attributedText
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
                make.height.equalTo(39 * 7).priority(999)
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

        self.controller.apply(click: .hours)
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
                label.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
                label.numberOfLines = 2
                self.addSubview(label)

                label.snp.makeConstraints { make in
                    make.left.right.equalTo(self)
                    make.height.equalTo(39).priority(998)

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

        func render(hourGrouped: Hour.Grouped) {
            func createLine(day: Hour.Day, dayText: String) -> NSAttributedString {
                if day.isToday {
                    switch hourGrouped.isOpen() {
                    case .opening: fallthrough
                    case .closing: fallthrough
                    case .open:
                        return dayText.set(style: PlaceBasicBusinessHourCard.boldStyle) + "\n"
                                + hourGrouped[day].set(style: PlaceBasicBusinessHourCard.openStyle)
                    case .closed: fallthrough
                    case .none:
                        return dayText.set(style: PlaceBasicBusinessHourCard.boldStyle) + "\n"
                                + hourGrouped[day].set(style: PlaceBasicBusinessHourCard.closeStyle)
                    }
                } else {
                    return NSAttributedString(string: "\(dayText)\n\(hourGrouped[day])")
                }
            }

            dayLabels[0].attributedText = createLine(day: Hour.Day.mon, dayText: "Monday")
            dayLabels[1].attributedText = createLine(day: Hour.Day.tue, dayText: "Tuesday")
            dayLabels[2].attributedText = createLine(day: Hour.Day.wed, dayText: "Wednesday")
            dayLabels[3].attributedText = createLine(day: Hour.Day.thu, dayText: "Thursday")
            dayLabels[4].attributedText = createLine(day: Hour.Day.fri, dayText: "Friday")
            dayLabels[5].attributedText = createLine(day: Hour.Day.sat, dayText: "Saturday")
            dayLabels[6].attributedText = createLine(day: Hour.Day.sun, dayText: "Sunday")
        }
    }
}


