//
// Created by Fuxing Loh on 20/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import TTGTagCollectionView

/**
 SearchHeader controls data managements query, update refresh
 SearchController only controls rendering of the data
 */
class SearchHeaderView: UIView, FilterTagViewDelegate {
    var controller: SearchController!

    let backButton = SearchBackButton()
    let textButton = SearchTextButton()
    let filterButton = SearchFilterButton()

    let tagButton: UIButton = {
        let button = UIButton()
        button.tintColor = UIColor(hex: "dbdbdb")
        button.setImage(UIImage(named: "Search-Filter-Tag"), for: .normal)
        return button
    }()
    let tagCollection = FilterTagView()

    var topConstraint: Constraint! = nil
    var queryHistories = [SearchQuery]()

    required init() {
        super.init(frame: .zero)
        self.initViews()
    }

    private func initViews() {
        self.backgroundColor = .white

        self.addSubview(tagButton)
        self.addSubview(tagCollection)
        self.addSubview(textButton)
        self.addSubview(backButton)
        self.addSubview(filterButton)

        self.tagCollection.delegate = self

        filterButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)
        textButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)
        tagButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)


        filterButton.snp.makeConstraints { make in
            make.width.equalTo(72)
            make.right.equalTo(self)
            make.height.equalTo(52)
            make.top.equalTo(self.safeArea.top)
        }

        textButton.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.right.equalTo(filterButton.snp.left)
            make.height.equalTo(52)
            make.top.equalTo(self.safeArea.top)
        }

        backButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.left.equalTo(self)
            make.width.equalTo(60)
            make.height.equalTo(56)
        }

        tagButton.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.top.bottom.equalTo(tagCollection)
        }

        tagCollection.snp.makeConstraints { make in
            make.left.equalTo(tagButton.snp.right).inset(-6)
            make.right.equalTo(self)
            self.topConstraint = make.top.equalTo(textButton.snp.bottom).constraint
            make.bottom.equalTo(self).inset(8)
            make.height.equalTo(34)
        }
    }

    @objc func onHeaderAction(for view: UIView) {
        if view is SearchTextButton {
            controller.goTo(extension: SearchSuggestController.self)
        } else if view is SearchBackButton {
            // When back button is clicked
            renderPrevious()
        } else if view is SearchFilterButton {
            controller.goTo(extension: SearchFilterController.self)
        } else if view == tagButton {
            controller.goTo(extension: SearchFilterController.self)
        }
    }

    func tagCollection(selectedLocation name: String, for tagCollection: FilterTagView) {
        controller.goTo(extension: SearchFilterController.self)
    }

    func tagCollection(selectedHour name: String, for tagCollection: FilterTagView) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { action in
            var searchQuery = self.controller.searchQuery
            searchQuery.filter.hour.name = nil
            searchQuery.filter.hour.open = nil
            searchQuery.filter.hour.close = nil
            searchQuery.filter.hour.close = nil
            self.controller.search(searchQuery: searchQuery)
        })
        addAlert(removeAll: alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.controller.present(alert, animated: true)
    }

    func tagCollection(selectedPrice name: String, for tagCollection: FilterTagView) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { action in
            var searchQuery = self.controller.searchQuery
            searchQuery.filter.price.name = nil
            searchQuery.filter.price.min = nil
            searchQuery.filter.price.max = nil
            self.controller.search(searchQuery: searchQuery)
        })
        addAlert(removeAll: alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.controller.present(alert, animated: true)
    }

    func tagCollection(selectedTag name: String, for tagCollection: FilterTagView) {
        if !UserSetting.allow(remove: name.lowercased(), controller: self.controller) {
            return
        }

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { action in
            var searchQuery = self.controller.searchQuery
            searchQuery.filter.tag.positives.remove(name)
            self.controller.search(searchQuery: searchQuery)
        })
        addAlert(removeAll: alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.controller.present(alert, animated: true)
    }

    func addAlert(removeAll alert: UIAlertController) {
        alert.addAction(UIAlertAction(title: "Remove All", style: .destructive) { action in
            self.controller.reset(force: true)
        })
    }

    func render(query: SearchQuery) {
        // Save a copy here if don't already exist for navigation
        if let last = queryHistories.last, last != query {
            queryHistories.append(query)
        }

        self.tagCollection.render(query: query)

        if (queryHistories.count > 1) {
            // Back Button
            textButton.field.leftImage = UIImage(named: "SC-Back-18")
            backButton.isHidden = false
        } else {
            // Search Button
            textButton.field.leftImage = UIImage(named: "SC-Search-18")
            backButton.isHidden = true
        }
    }

    func renderPrevious() {
        if let _ = queryHistories.popLast(), let last = queryHistories.last {
            self.controller.search(searchQuery: last)
        }
    }

    func getPrevious() -> SearchQuery {
        return queryHistories[queryHistories.count - 2]
    }

    func hasPrevious() -> Bool {
        return self.queryHistories.count > 1
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
enum FilterTagType {
    case location(String)
    case price(String)
    case hour(String)
    case tag(String)
}

class FilterTagView: UIView, TTGTextTagCollectionViewDelegate {
    let tagCollection: TTGTextTagCollectionView = {
        let tagCollection = TTGTextTagCollectionView()
        tagCollection.horizontalSpacing = 10
        tagCollection.numberOfLines = 1
        tagCollection.scrollDirection = .horizontal
        tagCollection.showsHorizontalScrollIndicator = false
        tagCollection.showsVerticalScrollIndicator = false
        tagCollection.alignment = .left
        tagCollection.contentInset = UIEdgeInsets(topBottom: 2, leftRight: 0)
        return tagCollection
    }()

    var delegate: FilterTagViewDelegate?
    var tags: [FilterTagType]!

    init(tagConfig: TTGTextTagConfig = DefaultTagConfig()) {
        super.init(frame: .zero)
        self.addSubview(tagCollection)

        tagCollection.delegate = self
        tagCollection.defaultConfig = tagConfig
        tagCollection.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }

    func render(query: SearchQuery) {
        render(tags: FilterTagView.resolve(query: query))
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FilterTagView {
    class func resolve(query: SearchQuery) -> [FilterTagType] {
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
        if let locationName = query.filter.area?.name {
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

// MARK: Search Text Field
class SearchTextField: UITextField {

    // Provides left padding for images
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var textRect = super.leftViewRect(forBounds: bounds)
        textRect.origin.x += leftImagePadding
        textRect.size.width = leftImageWidth
        return textRect
    }

    var leftImagePadding: CGFloat = 0
    var leftImageWidth: CGFloat = 20
    var leftImageSize: CGFloat = 18 {
        didSet {
            updateView()
        }
    }


    var leftImage: UIImage? {
        didSet {
            updateView()
        }
    }

    var color: UIColor = UIColor.lightGray {
        didSet {
            updateView()
        }
    }

    func updateView() {
        if let image = leftImage {
            leftViewMode = UITextFieldViewMode.always
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: leftImageSize, height: leftImageSize))
            imageView.contentMode = .scaleAspectFit

            imageView.image = image
            imageView.tintColor = color
            leftView = imageView
        } else {
            leftViewMode = UITextFieldViewMode.never
            leftView = nil
        }

        // Placeholder text color
        attributedPlaceholder = NSAttributedString(string: placeholder != nil ? placeholder! : "", attributes: [NSAttributedStringKey.foregroundColor: color])
    }
}

// MARK: Search Buttons
class SearchFilterButton: UIButton {
    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)

        setImage(UIImage(named: "Search-Filter"), for: .normal)
        tintColor = UIColor(hex: "333333")
        contentHorizontalAlignment = .right
        contentEdgeInsets.right = 24
        backgroundColor = .white
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchTextButton: UIButton {
    fileprivate let field = SearchTextField()

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white

        field.layer.cornerRadius = 4
        field.color = UIColor(hex: "303030")
        field.backgroundColor = UIColor(hex: "EBEBEB")

        field.leftImage = UIImage(named: "SC-Search-18")
        field.leftImagePadding = 3
        field.leftImageWidth = 32
        field.leftImageSize = 18

        field.placeholder = "Search e.g. Italian in Marina Bay"
        field.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)

        field.isEnabled = false

        self.addSubview(field)
        field.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.bottom.equalTo(self).inset(8)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchBackButton: UIButton {

}