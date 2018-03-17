//
//  DiscoverHeaderView.swift
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
class DiscoverHeaderView: UIView, FilterTagViewDelegate {
    var controller: DiscoverController!

    let backButton = DiscoverBackButton()
    let textButton = DiscoverTextButton()
    let filterButton = DiscoverFilterButton()
    let tagCollection = FilterTagView()

    var topConstraint: Constraint! = nil

    var searchQueryHistories = [SearchQuery]()

    required init() {
        super.init(frame: .zero)
        self.initViews()
    }

    private func initViews() {
        self.backgroundColor = .white

        self.addSubview(tagCollection)
        self.addSubview(textButton)
        self.addSubview(backButton)
        self.addSubview(filterButton)

        self.tagCollection.delegate = self

        filterButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)
        textButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)


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

        tagCollection.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            self.topConstraint = make.top.equalTo(textButton.snp.bottom).constraint
            make.bottom.equalTo(self).inset(8)
            make.height.equalTo(34)
        }
    }

    @objc func onHeaderAction(for view: UIView) {
        if view is DiscoverTextButton {
            // TODO Search Text
        } else if view is DiscoverBackButton {
            // When back button is clicked
            renderPrevious()
        } else if view is DiscoverFilterButton {
            controller.goTo(extension: DiscoverFilterController.self)
        }
    }

    func tagCollection(selectedLocation name: String, for tagCollection: FilterTagView) {
        // TODO Filter Location
        controller.goTo(extension: DiscoverFilterController.self)
    }

    func tagCollection(selectedHour name: String, for tagCollection: FilterTagView) {
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

    func tagCollection(selectedPrice name: String, for tagCollection: FilterTagView) {
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

    func tagCollection(selectedTag name: String, for tagCollection: FilterTagView) {
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
        self.shadow(vertical: 2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class DiscoverFilterButton: UIButton {
    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)

        setImage(UIImage(named: "Search-Filter"), for: .normal)
        tintColor = UIColor(hex: "222222")
        contentHorizontalAlignment = .right
        contentEdgeInsets.right = 24
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class DiscoverTextButton: UIButton {
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

class DiscoverBackButton: UIButton {

}

// Header Scroll to Hide Functions
extension DiscoverHeaderView {
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