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

/**
 SearchHeader controls data managements query, update refresh
 SearchController only controls rendering of the data
 */
class SearchHeaderView: UIView {
    let controller: UIViewController

    let textButton = SearchTextButton()
    let filterButton = SearchFilterButton()
    var heightConstraint: Constraint! = nil

    var searchQuery = SearchQuery()

    init(controller: UIViewController) {
        self.controller = controller
        super.init(frame: CGRect())
        self.backgroundColor = UIColor.white

        registerActions()
        initViews()
    }

    private func initViews() {
        let statusView = UIView()

        self.addSubview(statusView)
        self.addSubview(filterButton)
        self.addSubview(textButton)

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

        self.snp.makeConstraints { make in
            self.heightConstraint = make.height.equalTo(maxHeight).constraint
        }
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

// Header Scroll to Hide Functions
extension SearchHeaderView {
    var maxHeight: CGFloat {
        return 108
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

// Actions Functions Here
extension SearchHeaderView {
    func registerActions() {
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
}

class HeaderViewSegue: UIStoryboardSegue {
    override func perform() {
        super.perform()
        let searchQuery = (source as! SearchController).headerView.searchQuery

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