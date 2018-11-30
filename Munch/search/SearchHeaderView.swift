//
// Created by Fuxing Loh on 20/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

/**
 SearchHeader controls data managements query, update refresh
 SearchController only controls rendering of the data
 */
class SearchHeaderView: UIView {
    var controller: SearchController!

    let backButton = SearchBackButton()
    let textButton = SearchTextButton()
    let filterButton = SearchFilterButton()

    let tagView = SearchHeaderTagView()
    var topConstraint: Constraint! = nil

    required init() {
        super.init(frame: .zero)
        self.backgroundColor = .white

        self.addSubview(tagView)
        self.addSubview(backButton)
        self.addSubview(textButton)
        self.addSubview(filterButton)

        filterButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)
        textButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.left.equalTo(self)
            make.width.equalTo(60)
            make.height.equalTo(56)
        }

        textButton.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.right.equalTo(filterButton.snp.left)
            make.height.equalTo(52)
            make.top.equalTo(self.safeArea.top)
        }

        filterButton.snp.makeConstraints { make in
            make.width.equalTo(72)
            make.right.equalTo(self)
            make.height.equalTo(52)
            make.top.equalTo(self.safeArea.top)
        }

        tagView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)

            self.topConstraint = make.top.equalTo(textButton.snp.bottom).constraint
            make.bottom.equalTo(self).inset(8)
            make.height.equalTo(34)
        }
    }

    @objc func onHeaderAction(for view: UIView) {
        if view is SearchTextButton {
        } else if view is SearchBackButton {

        } else if view is SearchFilterButton {

        }
        // TODO
    }

//    func tagCollection(selectedLocation name: String, for tagCollection: SearchHeaderTagView) {
//        controller.goTo(where: .filter)
//    }
//
//    func tagCollection(selectedHour name: String, for tagCollection: SearchHeaderTagView) {
//        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//        alert.addAction(UIAlertAction(title: "Remove".localized(), style: .destructive) { action in
//            var searchQuery = self.controller.searchQuery
//            searchQuery.filter.hour.name = nil
//            searchQuery.filter.hour.open = nil
//            searchQuery.filter.hour.close = nil
//            searchQuery.filter.hour.close = nil
//            self.controller.search(searchQuery: searchQuery)
//        })
//        addAlert(removeAll: alert)
//        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
//        self.controller.present(alert, animated: true)
//    }
//
//    func tagCollection(selectedPrice name: String, for tagCollection: SearchHeaderTagView) {
//        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//        alert.addAction(UIAlertAction(title: "Remove".localized(), style: .destructive) { action in
//            var searchQuery = self.controller.searchQuery
//            searchQuery.filter.price.name = nil
//            searchQuery.filter.price.min = nil
//            searchQuery.filter.price.max = nil
//            self.controller.search(searchQuery: searchQuery)
//        })
//        addAlert(removeAll: alert)
//        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
//        self.controller.present(alert, animated: true)
//    }
//
//    func tagCollection(selectedTag name: String, for tagCollection: SearchHeaderTagView) {
//        guard UserSetting.allow(remove: name, controller: self.controller) else {
//            return
//        }
//
//        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//        alert.addAction(UIAlertAction(title: "Remove".localized(), style: .destructive) { action in
//            var searchQuery = self.controller.searchQuery
//            searchQuery.filter.tag.positives.remove(name)
//            self.controller.search(searchQuery: searchQuery)
//        })
//        addAlert(removeAll: alert)
//        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
//        self.controller.present(alert, animated: true)
//    }

    func addAlert(removeAll alert: UIAlertController) {
        alert.addAction(UIAlertAction(title: "Remove All".localized(), style: .destructive) { action in
//                self.controller.reset(force: true)
        })
    }

    func render(query: SearchQuery) {
        self.tagView.render(query: query)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: 2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// Header Scroll to Hide Functions
extension SearchHeaderView {
    static let contentHeight: CGFloat = 94

    var maxHeight: CGFloat {
        // contentHeight + safeArea.top
        return self.safeAreaInsets.top + SearchHeaderView.contentHeight
    }

    func contentDidScroll(scrollView: UIScrollView) {
        let height = calculateHeight(scrollView: scrollView)
        let inset = 38 - height
        self.topConstraint.update(inset: inset)
    }

    /**
     nil means don't move
     */
    func contentShouldMove(scrollView: UIScrollView) -> CGFloat? {
        let height = calculateHeight(scrollView: scrollView)

        // Already fully closed or opened
        if (height == 39.0 || height == 0.0) {
            return nil
        }

        if (height < 22) {
            // To close
            return -maxHeight + 39
        } else {
            // To open
            return -maxHeight
        }
    }

    private func calculateHeight(scrollView: UIScrollView) -> CGFloat {
        let y = scrollView.contentOffset.y

        if y <= -maxHeight {
            return 39
        } else if y >= -maxHeight + 39 {
            return 0
        } else {
            return 39 - (maxHeight + y)
        }
    }
}

// MARK: Filter View
enum SearchHeaderTag {
    case tag(Tag)
    case hour(SearchQuery.Filter.Hour)
    case price(SearchQuery.Filter.Price)
    case location(SearchQuery.Filter.Location)
}

extension SearchHeaderTag {
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

class SearchHeaderTagView: UIView {
    var tags = [SearchHeaderTag]()
    var first = TagView()
    var second = TagView()
    var third = TagView()

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

    func render(query: SearchQuery) {
        let tags = SearchHeaderTagView.getTags(query: query)
        self.first.render(tag: tags[0])
    }

    // TODO did click

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class TagView: UIView {
        let textLabel = UILabel()
                .with(size: 14, weight: 600, color: .ba80)

        override init(frame: CGRect = .zero) {
            super.init(frame: frame)
            self.addSubview(textLabel)

            self.backgroundColor = .whisper100
            self.layer.cornerRadius = 4

            self.textLabel.snp.makeConstraints { maker in
                maker.left.right.equalTo(self).inset(11)
                maker.top.bottom.equalTo(self)
            }

            textLabel.text = "Some"
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func render(tag: SearchHeaderTag) {
            self.textLabel.text = tag.text
        }
    }
}

extension SearchHeaderTagView {
    class func getTags(query: SearchQuery) -> [SearchHeaderTag] {
        var tags = [SearchHeaderTag]()
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

// MARK: Buttons
class SearchBackButton: UIButton {

}

class SearchFilterButton: UIButton {
    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)

        setImage(UIImage(named: "Search-Filter"), for: .normal)
        tintColor = .ba85
        contentHorizontalAlignment = .right
        contentEdgeInsets.right = 24
        backgroundColor = .white
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchTextButton: UIButton {
    fileprivate let field = MunchSearchTextField()

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.addSubview(field)
        self.backgroundColor = .white

        field.isEnabled = false
        field.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.bottom.equalTo(self).inset(8)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}