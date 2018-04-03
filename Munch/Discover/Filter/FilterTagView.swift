//
// Created by Fuxing Loh on 17/3/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import TTGTagCollectionView

enum FilterTagType {
    case location(String)
    case price(String)
    case hour(String)
    case tag(String)
}

class FilterTagView: UIView, TTGTextTagCollectionViewDelegate {
    let tagCollection = TTGTextTagCollectionView()
    let defaultTagConfig: TTGTextTagConfig

    var delegate: FilterTagViewDelegate?
    var tags: [FilterTagType]!

    init(tagConfig: TTGTextTagConfig = DefaultTagConfig()) {
        self.defaultTagConfig = tagConfig
        super.init(frame: .zero)
        self.addSubview(tagCollection)

        tagCollection.delegate = self
        tagCollection.defaultConfig = defaultTagConfig
        tagCollection.horizontalSpacing = 10
        tagCollection.numberOfLines = 1
        tagCollection.scrollDirection = .horizontal
        tagCollection.showsHorizontalScrollIndicator = false
        tagCollection.showsVerticalScrollIndicator = false
        tagCollection.alignment = .left
        tagCollection.contentInset = UIEdgeInsets(topBottom: 2, leftRight: 0)
        tagCollection.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }

    func render(query: SearchQuery) {
        render(tags: FilterTagView.resolve(query: query))
    }

    class func resolve(query: SearchQuery) -> [FilterTagType]{
        var tags = [FilterTagType]()

        // FirstTag is always Location Tag
        tags.append(contentsOf: getLocationTag(query: query))
        tags.append(contentsOf: getHourTag(query: query))
        tags.append(contentsOf: getPriceTag(query: query))
        tags.append(contentsOf: getFilterTags(query: query))

        return tags
    }

    private class func getFilterTags(query: SearchQuery) -> [FilterTagType] {
        var tags = [FilterTagType]()
        for tag in query.filter.tag.positives {
            tags.append(FilterTagType.tag(tag))
        }

        if tags.isEmpty {
            return []
        }
        return tags
    }

    /**
     Must always return one returns min
     */
    private class func getLocationTag(query: SearchQuery) -> [FilterTagType] {
        if let containers = query.filter.containers, !containers.isEmpty {
            return containers.map({ FilterTagType.location($0.name ?? "Container") })
        }

        if let locationName = query.filter.location?.name {
            return [FilterTagType.location(locationName)]
        }

        if MunchLocation.isEnabled {
            return [FilterTagType.location("Nearby")]
        }

        return [FilterTagType.location("Singapore")]
    }

    private class func getPriceTag(query: SearchQuery) -> [FilterTagType] {
        if let min = query.filter.price.min, let max = query.filter.price.max {
            let min = String(format: "%.0f", min)
            let max = String(format: "%.0f", max)
            return [FilterTagType.price("$\(min) - $\(max)")]
        }
        return []
    }

    private class func getHourTag(query: SearchQuery) -> [FilterTagType] {
        if let name = query.filter.hour.name {
            return [FilterTagType.hour(name)]
        } else if let day = query.filter.hour.day,
                  let open = query.filter.hour.open,
                  let close = query.filter.hour.close {
            return [FilterTagType.hour("\(day): \(open)-\(close)")]
        }
        return []
    }

    private func render(tags: [FilterTagType]) {
        tagCollection.removeAllTags()
        self.tags = tags
        for tag in tags {
            switch tag {
            case let .location(name):
                tagCollection.addTag(name)
            case let .price(name):
                tagCollection.addTag(name)
            case let .hour(name):
                tagCollection.addTag(name)
            case let .tag(name):
                tagCollection.addTag(name)
            }
        }
    }

    class DefaultTagConfig: TTGTextTagConfig {
        override init() {
            super.init()
            tagTextFont = UIFont.systemFont(ofSize: 14.0, weight: .regular)
            tagShadowOffset = CGSize.zero
            tagShadowRadius = 0
            tagCornerRadius = 4

            tagBorderWidth = 1.0
            tagBorderColor = UIColor.clear
            tagTextColor = UIColor(hex: "303030")
            tagBackgroundColor = UIColor(hex: "EBEBEB")

            tagSelectedBorderWidth = 1.0
            tagSelectedBorderColor = UIColor.clear
            tagSelectedTextColor = UIColor(hex: "303030")
            tagSelectedBackgroundColor = UIColor(hex: "EBEBEB")

            tagExtraSpace = CGSize(width: 21, height: 13)
        }
    }

    class OrTagConfig: TTGTextTagConfig {
        override init() {
            super.init()
            tagTextFont = UIFont.systemFont(ofSize: 14.0, weight: .regular)
            tagShadowOffset = CGSize.zero
            tagShadowRadius = 0
            tagCornerRadius = 4

            tagBorderWidth = 1.0
            tagBorderColor = .clear
            tagTextColor = UIColor(hex: "404040")
            tagBackgroundColor = .clear

            tagSelectedBorderWidth = 1.0
            tagSelectedBorderColor = .clear
            tagSelectedTextColor = UIColor(hex: "404040")
            tagSelectedBackgroundColor = .clear

            tagExtraSpace = CGSize(width: 0, height: 13)
        }
    }


    func textTagCollectionView(_ textTagCollectionView: TTGTextTagCollectionView!, didTapTag tagText: String!, at index: UInt, selected: Bool) {
        switch tags[Int(index)] {
        case let .location(name):
            delegate?.tagCollection(selectedLocation: name, for: self)
        case let .price(name):
            delegate?.tagCollection(selectedPrice: name, for: self)
        case let .hour(name):
            delegate?.tagCollection(selectedHour: name, for: self)
        case let .tag(name):
            delegate?.tagCollection(selectedTag: name, for: self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/**
 Delegate tool for SearchFilterTag
 */
protocol FilterTagViewDelegate {
    func tagCollection(selectedLocation name: String, for tagCollection: FilterTagView)

    func tagCollection(selectedHour name: String, for tagCollection: FilterTagView)

    func tagCollection(selectedPrice name: String, for tagCollection: FilterTagView)

    func tagCollection(selectedTag name: String, for tagCollection: FilterTagView)
}