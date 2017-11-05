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
class SearchHeaderView: UIView {
    let controller: UIViewController

    let textButton = SearchTextButton()
    let filterButton = SearchFilterButton()
    let tagCollection = SearchFilterTagCollection()

    var heightConstraint: Constraint! = nil

    var searchQuery = SearchQuery()

    init(controller: UIViewController) {
        self.controller = controller
        super.init(frame: CGRect())
        self.backgroundColor = UIColor.white

        linkActions()
        self.makeConstraints()
    }

    private func makeConstraints() {
        let statusView = UIView()

        self.addSubview(tagCollection)
        self.addSubview(filterButton)
        self.addSubview(textButton)
        self.addSubview(statusView)

        statusView.backgroundColor = UIColor.white
        statusView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self)
            make.height.equalTo(20)
        }

        textButton.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.right.equalTo(filterButton.snp.left)
            make.height.equalTo(52)
            make.top.equalTo(statusView.snp.bottom)
        }

        filterButton.imageEdgeInsets.right = 24
        filterButton.snp.makeConstraints { make in
            make.right.equalTo(self)
            make.width.equalTo(45 + 24)
            make.height.equalTo(52)
            make.top.equalTo(statusView.snp.bottom)
        }

        tagCollection.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.bottom.equalTo(self).inset(8)
        }

        self.snp.makeConstraints { make in
            self.heightConstraint = make.height.equalTo(maxHeight).constraint
        }
    }

    private func linkActions() {
        textButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)
        filterButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)
        // TODO Filter Tags
    }

    @objc func onHeaderAction(for view: UIView) {
        if view is SearchTextButton {
            controller.performSegue(withIdentifier: "SearchHeaderView_suggest", sender: self)
        } else if view is SearchFilterButton {
            controller.performSegue(withIdentifier: "SearchHeaderView_filter", sender: self)
        }
    }

    func render(query: SearchQuery) {
        self.textButton.setTitle(query.query, for: .normal)
        self.tagCollection.render(query: query)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.hairlineShadow(height: 1.0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchTextButton: UIButton {
    let field = SearchTextField()

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white

        field.layer.cornerRadius = 4
        field.color = UIColor(hex: "2E2E2E")
        field.backgroundColor = UIColor.init(hex: "EBEBEB")

        field.leftImage = UIImage(named: "SC-Search-18")
        field.leftImagePadding = 3
        field.leftImageWidth = 32
        field.leftImageSize = 18

        field.placeholder = "Any restaurant or cuisine"
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

class SearchFilterButton: UIButton {
    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)

        self.setImage(UIImage(named: "icons8-Horizontal Settings Mixer-30"), for: .normal)
        self.tintColor = UIColor.black
        self.contentHorizontalAlignment = .right
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchFilterTagCollection: UIView, TTGTextTagCollectionViewDelegate {
    let tagCollection = TTGTextTagCollectionView()

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.addSubview(tagCollection)

        tagCollection.delegate = self
        tagCollection.defaultConfig.tagTextFont = UIFont.systemFont(ofSize: 13.0, weight: .regular)
        tagCollection.defaultConfig.tagTextColor = UIColor.black.withAlphaComponent(0.75)

        tagCollection.defaultConfig.tagBackgroundColor = UIColor.white
        tagCollection.defaultConfig.tagSelectedBackgroundColor = UIColor.white

        tagCollection.defaultConfig.tagBorderWidth = 0.5
        tagCollection.defaultConfig.tagBorderColor = UIColor.black.withAlphaComponent(0.25)
        tagCollection.defaultConfig.tagShadowOffset = CGSize.zero
        tagCollection.defaultConfig.tagShadowRadius = 0

        tagCollection.defaultConfig.tagSelectedBorderWidth = 0
        tagCollection.defaultConfig.tagExtraSpace = CGSize(width: 21, height: 13)

        tagCollection.horizontalSpacing = 10
        tagCollection.contentInset = UIEdgeInsets.init(topBottom: 2, leftRight: 0)

        tagCollection.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }

    func render(query: SearchQuery) {
        tagCollection.removeAllTags()

        // FirstTag: Location Tag
        if let location = query.location {
            tagCollection.addTag(location.name)
        } else if MunchLocation.isEnabled {
            tagCollection.addTag("Nearby")
        } else {
            tagCollection.addTag("Singapore")
        }

        // Other Tags
        for tag in query.filter.tag.positives {
            tagCollection.addTag(tag)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class HeaderViewSegue: UIStoryboardSegue {
    override func perform() {
        super.perform()
        let searchQuery = (source as! SearchController).searchQuery

        if let navigation = destination as? UINavigationController {
            let controller = navigation.topViewController
            if let query = controller as? SearchQueryController {
                query.searchQuery = searchQuery
            } else if let filter = controller as? SearchFilterController {
                filter.searchQuery = searchQuery
            } else if let location = controller as? SearchLocationController {
                location.searchQuery = searchQuery
            }
        }
    }
}

// Header Scroll to Hide Functions
extension SearchHeaderView {
    var maxHeight: CGFloat {
        return 114
    }
    var minHeight: CGFloat {
        return 75
    }
    var centerHeight: CGFloat {
        return minHeight + 23
    }

    func contentDidScroll(scrollView: UIScrollView) {
        let height = calculateHeight(scrollView: scrollView)
        self.heightConstraint.layoutConstraints[0].constant = height
    }

    /**
     nil means don't move
     */
    func contentShouldMove(scrollView: UIScrollView) -> CGFloat? {
        let height = calculateHeight(scrollView: scrollView)

        // Already fully closed or opened
        if (height == maxHeight || height == minHeight) {
            return nil
        }

        if (height < centerHeight) {
            // To close
            return -minHeight
        } else {
            // To open
            return -maxHeight
        }
    }

    private func calculateHeight(scrollView: UIScrollView) -> CGFloat {
        let y = scrollView.contentOffset.y
        if y <= -maxHeight {
            return maxHeight
        } else if y >= -minHeight {
            return minHeight
        } else {
            return Swift.abs(y)
        }
    }
}