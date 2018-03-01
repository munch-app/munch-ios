//
//  SearchHeaderView.swift
//  Munch
//
//  Created by Fuxing Loh on 16/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import TTGTagCollectionView

/**
 SearchHeader controls data managements query, update refresh
 SearchController only controls rendering of the data
 */
class SearchHeaderView: UIView, SearchFilterTagDelegate {
    var controller: SearchController!

    let backButton = SearchBackButton()
    let textButton = SearchTextButton()
    let mapButton = SearchMapButton()
    let tagCollection = SearchFilterTagCollection()

    var topConstraint: Constraint! = nil

    var searchQueryHistories = [SearchQuery]()

    required init(showMapBtn: Bool = true) {
        super.init(frame: .zero)
        self.tagCollection.delegate = self
        self.initViews(showMapBtn: showMapBtn)
    }

    private func initViews(showMapBtn: Bool) {
        self.backgroundColor = .white

        self.addSubview(tagCollection)
        self.addSubview(textButton)
        self.addSubview(backButton)

        if (showMapBtn) {
            self.addSubview(mapButton)

            mapButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)
            mapButton.snp.makeConstraints { make in
                make.width.equalTo(72)
                make.right.equalTo(self)
                make.height.equalTo(52)
                make.top.equalTo(self.safeArea.top)
            }
        }

        textButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)
        textButton.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            if showMapBtn {
                make.right.equalTo(mapButton.snp.left)
            } else {
                make.right.equalTo(self).inset(24)
            }
            make.height.equalTo(52)
            make.top.equalTo(self.safeArea.top)
        }

        backButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)
        backButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.left.equalTo(self)
            make.width.equalTo(60)
            make.height.equalTo(56)
        }

        tagCollection.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
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
        }
    }

    func tagCollection(selectedLocation name: String, for tagCollection: SearchFilterTagCollection) {
        controller.goTo(extension: SearchSuggestController.self)
    }

    func tagCollection(selectedHour name: String, for tagCollection: SearchFilterTagCollection) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { action in
            var searchQuery = self.controller.searchQuery
            searchQuery.filter.hour.name = nil
            searchQuery.filter.hour.open = nil
            searchQuery.filter.hour.close = nil
            searchQuery.filter.hour.close = nil
            self.controller.render(searchQuery: searchQuery)
        })
        addAlert(removeAll: alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.controller.present(alert, animated: true)
    }

    func tagCollection(selectedPrice name: String, for tagCollection: SearchFilterTagCollection) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { action in
            var searchQuery = self.controller.searchQuery
            searchQuery.filter.price.name = nil
            searchQuery.filter.price.min = nil
            searchQuery.filter.price.max = nil
            self.controller.render(searchQuery: searchQuery)
        })
        addAlert(removeAll: alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.controller.present(alert, animated: true)
    }

    func tagCollection(selectedTag name: String, for tagCollection: SearchFilterTagCollection) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { action in
            var searchQuery = self.controller.searchQuery
            searchQuery.filter.tag.positives.remove(name)
            self.controller.render(searchQuery: searchQuery)
        })
        addAlert(removeAll: alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.controller.present(alert, animated: true)
    }

    func addAlert(removeAll alert: UIAlertController) {
        alert.addAction(UIAlertAction(title: "Remove All", style: .destructive) { action in
            let searchQuery = SearchQuery()
            self.controller.contentView(search: searchQuery)
            self.searchQueryHistories.removeAll()
            self.render(query: searchQuery)
        })
    }

    func render(query: SearchQuery) {
        // Save a copy here if don't already exist for navigation
        if (searchQueryHistories.last != query) {
            searchQueryHistories.append(query)
        }

        self.textButton.render(query: query)
        self.tagCollection.render(query: query)
        if (searchQueryHistories.count > 1) {
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
        if let _ = searchQueryHistories.popLast(), let last = searchQueryHistories.last {
            controller.contentView(search: last, animated: false)
            render(query: last)
        }
    }

    func getPrevious() -> SearchQuery {
        return searchQueryHistories[searchQueryHistories.count - 2]
    }

    func hasPrevious() -> Bool {
        return self.searchQueryHistories.count > 1
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: 1.5)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchMapButton: UIButton {
    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)

        setImage(UIImage(named: "Search-Filter"), for: .normal)
        tintColor = UIColor.black.withAlphaComponent(0.65)
        contentHorizontalAlignment = .right
        contentEdgeInsets.right = 24
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

        field.placeholder = "Search Anything"
        field.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)

        field.isEnabled = false

        self.addSubview(field)
        field.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.bottom.equalTo(self).inset(8)
        }
    }

    func render(query: SearchQuery) {
        self.field.text = query.query
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchBackButton: UIButton {

}

enum SearchFilterTagType {
    case location(String)
    case price(String)
    case hour(String)
    case tag(String)
}

class SearchFilterTagCollection: UIView, TTGTextTagCollectionViewDelegate {
    let tagCollection = TTGTextTagCollectionView()
    let defaultTagConfig = DefaultTagConfig()
    let plusTagConfig = DefaultTagConfig()

    var delegate: SearchFilterTagDelegate?
    var tags: [SearchFilterTagType]!

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.addSubview(tagCollection)
        plusTagConfig.tagTextFont = UIFont.systemFont(ofSize: 17.0, weight: .light)
        plusTagConfig.tagExtraSpace = CGSize(width: 13, height: 8)

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
        var tags = [SearchFilterTagType]()

        // FirstTag: Location Tag
        tags.append(contentsOf: getLocationTag(query: query))
        tags.append(contentsOf: getHourTag(query: query))
        tags.append(contentsOf: getPriceTag(query: query))

        // Other Tags
        for tag in query.filter.tag.positives {
            tags.append(SearchFilterTagType.tag(tag))
        }

        render(tags: tags)
    }

    /**
     Must always return one returns min
     */
    private func getLocationTag(query: SearchQuery) -> [SearchFilterTagType] {
        if let containers = query.filter.containers, !containers.isEmpty {
            return containers.map({ SearchFilterTagType.location($0.name ?? "Container") })
        }

        if let locationName = query.filter.location?.name {
            return [SearchFilterTagType.location(locationName)]
        }

        if MunchLocation.isEnabled {
            return [SearchFilterTagType.location("Nearby")]
        }

        return [SearchFilterTagType.location("Singapore")]
    }

    private func getPriceTag(query: SearchQuery) -> [SearchFilterTagType] {
        if let min = query.filter.price.min, let max = query.filter.price.max {
            let min = String(format: "%.0f", min)
            let max = String(format: "%.0f", max)
            return [SearchFilterTagType.price("$\(min) - $\(max)")]
        }
        return []
    }

    private func getHourTag(query: SearchQuery) -> [SearchFilterTagType] {
        if let name = query.filter.hour.name {
            return [SearchFilterTagType.hour(name)]
        } else if let day = query.filter.hour.day,
                  let open = query.filter.hour.open,
                  let close = query.filter.hour.close {
            return [SearchFilterTagType.hour("\(day): \(open)-\(close)")]
        }
        return []
    }

    private func render(tags: [SearchFilterTagType]) {
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
protocol SearchFilterTagDelegate {
    func tagCollection(selectedLocation name: String, for tagCollection: SearchFilterTagCollection)

    func tagCollection(selectedHour name: String, for tagCollection: SearchFilterTagCollection)

    func tagCollection(selectedPrice name: String, for tagCollection: SearchFilterTagCollection)

    func tagCollection(selectedTag name: String, for tagCollection: SearchFilterTagCollection)
}

// Header Scroll to Hide Functions
extension SearchHeaderView {
    var contentHeight: CGFloat {
        return 94
    }

    var maxHeight: CGFloat {
        // contentHeight + safeArea.top
        return self.safeAreaInsets.top + contentHeight
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

/**
 Designable search field for Discovery page
 */
@IBDesignable class SearchTextField: UITextField {

    // Provides left padding for images
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var textRect = super.leftViewRect(forBounds: bounds)
        textRect.origin.x += leftImagePadding
        textRect.size.width = leftImageWidth
        return textRect
    }

    @IBInspectable var leftImagePadding: CGFloat = 0
    @IBInspectable var leftImageWidth: CGFloat = 20
    @IBInspectable var leftImageSize: CGFloat = 18 {
        didSet {
            updateView()
        }
    }


    @IBInspectable var leftImage: UIImage? {
        didSet {
            updateView()
        }
    }

    @IBInspectable var color: UIColor = UIColor.lightGray {
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