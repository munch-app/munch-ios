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
    private static let descriptionFont = UIFont.systemFont(ofSize: 16.0, weight: .regular)
    private let titleLabel = UILabel()
            .with(style: .h2)
            .with(color: .white)
            .with(text: "Can’t decide?".localized())
            .with(numberOfLines: 1)

    private let descriptionLabel = UILabel()
            .with(font: descriptionFont)
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
        collectionView.register(SearchCardTagCell.self, forCellWithReuseIdentifier: "SearchCardTagCell")
        collectionView.backgroundColor = .clear
        return collectionView
    }()

    private var tags = [(String, Int)]()

    override func didLoad(card: SearchCard) {
        self.backgroundColor = .primary300
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

        self.tags = (card["tags"] as? [[String: Any]])?.compactMap { dictionary in
            if let name = dictionary["name"] as? String, let count = dictionary["count"] as? Int {
                return (name, count)
            }
            return nil
        } ?? []

        self.collectionView.setContentOffset(.zero, animated: false)
        self.collectionView.reloadData()
    }

    override class func height(card: SearchCard) -> CGFloat {
        let height = tagSize.height + (topBottom * 4)
                // For first label height
                + 24.0

        let titleWidth = width - (leftRight + leftRight)
        if let locationName = card.string(name: "locationName") {
            let text = "Here are some suggestions of what’s good in".localized() + " \(locationName)."
            return UILabel.textHeight(withWidth: titleWidth, font: descriptionFont, text: text) + height
        } else {
            let text = "Here are some suggestions of what’s good nearby.".localized()
            return UILabel.textHeight(withWidth: titleWidth, font: descriptionFont, text: text) + height
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
        let tag = tags[indexPath.row]

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchCardTagCell", for: indexPath) as! SearchCardTagCell
        cell.render(name: tag.0, count: tag.1)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tag = tags[indexPath.row]

        // TODO Editing
//        controller.push { query in
//
//        }

//        controller.search { query in
//            query.filter.tag.positives.insert(tag.0)
//        }
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

        func render(name: String, count: Int) {
            self.nameLabel.text = name.capitalized
            self.countLabel.text = "\(count) " + "places".localized()
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