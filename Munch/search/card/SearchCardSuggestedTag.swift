//
// Created by Fuxing Loh on 13/5/18.
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

class SearchTagSuggestion: SearchCardView {
    private let titleLabel = UILabel()
            .with(style: .h2)
            .with(color: .white)
            .with(text: "Can't decide?")
            .with(numberOfLines: 1)

    private let descriptionLabel = UILabel(style: .h6)
            .with(color: .white)
            .with(numberOfLines: 0)

    private static let tagSize = CGSize(width: 120, height: 70)
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = tagSize
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 18

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(type: SearchCardTagCell.self)
        collectionView.backgroundColor = .clear
        return collectionView
    }()

    private var tags = [FilterTag]()

    override func didLoad(card: SearchCard) {
        self.backgroundColor = .primary500
        self.addSubview(titleLabel)
        self.addSubview(descriptionLabel)
        self.addSubview(collectionView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(topBottom)
            make.height.equalTo(24.0)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(titleLabel.snp.bottom).inset(-topBottom)
        }

        collectionView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(descriptionLabel.snp.bottom).inset(-topBottom)
            make.bottom.equalTo(self).inset(topBottom)
            make.height.equalTo(SearchTagSuggestion.tagSize.height)
        }
    }

    override func willDisplay(card: SearchCard) {
        if let locationName = card.string(name: "locationName") {
            self.descriptionLabel.text = "Here are some suggestions of what’s good in".localized() + " \(locationName)."
        } else {
            self.descriptionLabel.text = "Here are some suggestions of what’s good nearby.".localized()
        }

        self.tags = card.decode(name: "tags", [FilterTag].self) ?? []
        self.collectionView.setContentOffset(.zero, animated: false)
        self.collectionView.reloadData()
    }

    override class func height(card: SearchCard) -> CGFloat {
        let height = tagSize.height + (topBottom * 4) + 24.0

        if let locationName = card.string(name: "locationName") {
            let text = "Here are some suggestions of what’s good in".localized() + " \(locationName)."
            return FontStyle.h6.height(text: text, width: contentWidth) + height
        } else {
            let text = "Here are some suggestions of what’s good nearby.".localized()
            return FontStyle.h6.height(text: text, width: contentWidth) + height
        }
    }

    override class var cardId: String {
        return "SuggestedTag_2018-05-11"
    }
}

extension SearchTagSuggestion: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(type: SearchCardTagCell.self, for: indexPath)
        cell.filterTag = tags[indexPath.row]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tag: FilterTag = tags[indexPath.row]
        guard let type = Tag.TagType(rawValue: tag.type) else {
            return
        }

        controller.push { query in
            query.filter.tags.append(Tag(tagId: tag.tagId, name: tag.name, type: type))
        }
    }

    fileprivate class SearchCardTagCell: UICollectionViewCell {
        let grid: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor.white
            return view
        }()
        let nameLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 14.0, weight: .bold)
            label.textColor = UIColor.black.withAlphaComponent(0.85)
            label.textAlignment = .center
            return label
        }()
        let countLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 13.0, weight: .medium)
            label.textColor = UIColor.black.withAlphaComponent(0.77)
            label.textAlignment = .center
            return label
        }()

        var filterTag: FilterTag! {
            didSet {
                self.nameLabel.text = filterTag.name.capitalized
                self.countLabel.text = "\(filterTag.count) " + "places".localized()
            }
        }

        override init(frame: CGRect = .zero) {
            super.init(frame: frame)
            self.addSubview(grid)
            self.addSubview(nameLabel)
            self.addSubview(countLabel)

            grid.snp.makeConstraints { make in
                make.edges.equalTo(self)
            }

            nameLabel.snp.makeConstraints { make in
                make.left.right.equalTo(self).inset(2)
                make.top.equalTo(self).inset(17)
            }

            countLabel.snp.makeConstraints { make in
                make.left.right.equalTo(self).inset(2)
                make.bottom.equalTo(self).inset(17)
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        fileprivate override func layoutSubviews() {
            super.layoutSubviews()
            self.grid.layer.cornerRadius = 3
        }
    }

}
