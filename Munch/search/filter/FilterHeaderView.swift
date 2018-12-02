//
// Created by Fuxing Loh on 2018-12-02.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import Localize_Swift

class FilterHeaderView: UIView {
    let tagView = FilterHeaderTagView()
    let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Search-Close"), for: .normal)
        button.tintColor = .black
        button.imageEdgeInsets.right = 18
        button.contentHorizontalAlignment = .right
        return button
    }()

    var manager: FilterManager!
    var searchQuery: SearchQuery? {
        didSet {
            self.tagView.query = self.searchQuery
        }
    }

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.backgroundColor = .white

        self.addSubview(tagView)
        self.addSubview(closeButton)

        tagView.snp.makeConstraints { maker in
            maker.top.equalTo(self.safeArea.top).inset(10)
            maker.height.equalTo(32)
            maker.bottom.equalTo(self).inset(10)

            maker.left.equalTo(self).inset(24)
            maker.right.equalTo(closeButton.snp_right).inset(-18)
        }

        closeButton.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(tagView)

            maker.right.equalTo(self)
            maker.width.equalTo(64)
        }
    }

    var tags: [FilterHeaderTag] = []

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: 2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FilterHeaderTagView: UIView {
    var first = TagView()
    var second = TagView()
    var third = TagView()

    var tags = [FilterHeaderTag]()
    var query: SearchQuery? {
        didSet {
            if let query = self.query {
                let tags = FilterHeaderTag.getTags(query: query)
                self.first.text = tags.get(0)?.text
                self.second.text = tags.get(1)?.text

                let count = tags.count - 2
                self.third.text = count > 0 ? "+\(count)" : nil
            } else {
                self.first.text = nil
                self.second.text = nil
                self.third.text = nil
            }
        }
    }

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(first)
        self.addSubview(second)
        self.addSubview(third)

        first.snp.makeConstraints { maker in
            maker.left.equalTo(self)
            maker.top.bottom.equalTo(self)
        }

        second.snp.makeConstraints { maker in
            maker.left.equalTo(first.snp_right).inset(-10)
            maker.top.bottom.equalTo(self)
        }

        third.snp.makeConstraints { maker in
            maker.left.equalTo(second.snp_right).inset(-10)
            maker.top.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class TagView: UIButton {
        private let textLabel = UILabel()
                .with(size: 14, weight: .medium, color: .ba80)

        var text: String? {
            set(value) {
                if let value = value {
                    self.isHidden = false
                    self.textLabel.text = value
                } else {
                    self.isHidden = true
                }
            }
            get {
                return self.textLabel.text
            }
        }

        override init(frame: CGRect = .zero) {
            super.init(frame: frame)
            self.addSubview(textLabel)

            self.backgroundColor = .whisper100
            self.layer.cornerRadius = 4

            self.textLabel.snp.makeConstraints { maker in
                maker.left.right.equalTo(self).inset(11)
                maker.top.bottom.equalTo(self)
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

// MARK: Filter View
enum FilterHeaderTag {
    case tag(Tag)
    case hour(SearchQuery.Filter.Hour)
    case price(SearchQuery.Filter.Price)
    case location(SearchQuery.Filter.Location)
}

extension FilterHeaderTag {
    var text: String {
        switch self {
        case .tag(let tag):
            return tag.name

        case .price(let price):
            let min = String(format: "%.0f", price.min)
            let max = String(format: "%.0f", price.max)
            return "$\(min) - $\(max)"

        case .location(let location):
            switch location.type {
            case .Anywhere:
                return "Anywhere"
            case .Nearby:
                return "Nearby"
            case .Between:
                return "EatBetween"
            case .Where:
                return location.areas.get(0)?.name ?? "Where"
            }

        case .hour(let hour):
            switch hour.type {
            case .OpenDay:
                let day = hour.day
                let open = hour.open
                let close = hour.close
                return "\(day): \(open)-\(close)"

            case .OpenNow:
                return "Open Now"
            }
        }
    }
}

extension FilterHeaderTag {
    static func getTags(query: SearchQuery) -> [FilterHeaderTag] {
        var tags = [FilterHeaderTag]()
        tags.append(.location(query.filter.location))

        if let price = query.filter.price {
            tags.append(.price(price))
        }

        if let hour = query.filter.hour {
            tags.append(.hour(hour))
        }

        query.filter.tags.forEach { tag in
            tags.append(.tag(tag))
        }
        return tags
    }
}