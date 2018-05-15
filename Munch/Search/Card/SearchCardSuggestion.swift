//
// Created by Fuxing Loh on 13/5/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import MapKit

import FirebaseAnalytics
import SnapKit
import SwiftRichString

import SwiftyJSON

class SearchCardSuggestionTag: UITableViewCell, SearchCardView {
    private let titleLabel: SearchHeaderCardLabel = {
        let label = SearchHeaderCardLabel()
        label.text = "Popular Tags Near You"
        return label
    }()
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
        collectionView.backgroundColor = UIColor.white
        collectionView.register(SearchCardTagCell.self, forCellWithReuseIdentifier: "SearchCardTagCell")
        return collectionView
    }()

    private var controller: DiscoverController!
    private var tags = [(String, Int)]()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
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
            make.height.equalTo(SearchCardSuggestionTag.tagSize.height)
        }
    }

    func render(card: SearchCard, controller: DiscoverController) {
        if let locationName = card.string(name: "locationName") {
            self.titleLabel.text = "Popular tags in '\(locationName)'"
        } else {
            self.titleLabel.text = "Popular tags nearby"
        }

        self.controller = controller
        self.tags = card["tags"].compactMap({
            if let name = $0.1["name"].string, let count = $0.1["count"].int {
                return (name, count)
            }
            return nil
        })

        self.collectionView.setContentOffset(.zero, animated: false)
        self.collectionView.reloadData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private(set) static var cardId: String = "injected_SuggestedTag_20180511"
}

extension SearchCardSuggestionTag: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tag = tags[indexPath.row]

        Analytics.logEvent(AnalyticsEventViewItem, parameters: [
            AnalyticsParameterItemID: "suggestion-tag-\(tag.0)" as NSObject,
            AnalyticsParameterItemCategory: "discover_suggestion_tag" as NSObject
        ])

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchCardTagCell", for: indexPath) as! SearchCardTagCell
        cell.render(name: tag.0, count: tag.1)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tag = tags[indexPath.row]

        var searchQuery = controller.searchQuery
        searchQuery.filter.tag.positives.insert(tag.0.capitalized)
        controller.render(searchQuery: searchQuery)

        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
            AnalyticsParameterItemID: "suggestion-tag-\(tag.0)" as NSObject,
            AnalyticsParameterContentType: "discover_suggestion_tag" as NSObject
        ])
    }

    fileprivate class SearchCardTagCell: UICollectionViewCell {
        let grid: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor.bgTag
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
            self.countLabel.text = "\(count) places"
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
