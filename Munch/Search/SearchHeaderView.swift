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

protocol SearchHeaderDelegate {
    func headerView(render query: SearchQuery)
}

/**
 SearchHeader controls data managements query, update refresh
 SearchController only controls rendering of the data
 */
class SearchHeaderView: UIView {
    var controller: SearchController!
    
    let locationButton = SearchLocationButton()
    let queryLabel = SearchQueryLabel()
    let filterButton = SearchFilterButton()
    var heightConstraint: Constraint! = nil
    
    var searchQuery = SearchQuery()
    
    init(controller: SearchController) {
        super.init(frame: CGRect())
        self.controller = controller
        
        self.backgroundColor = UIColor.white
        
        self.addSubview(locationButton)
        self.addSubview(queryLabel)
        self.addSubview(filterButton)
        
        registerActions()
        
        let statusView = UIView()
        statusView.backgroundColor = UIColor.white
        self.addSubview(statusView)
        
        self.snp.makeConstraints { make in
            self.heightConstraint = make.height.equalTo(maxHeight).constraint
        }
        
        statusView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self)
            make.height.equalTo(20)
        }

        locationButton.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.height.equalTo(45)
            make.bottom.equalTo(queryLabel.snp.top)
        }
        
        // TODO Bottom for queryLabel and filterButton
        queryLabel.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.right.equalTo(filterButton.snp.left)
            make.height.equalTo(32)
            make.bottom.equalTo(self).inset(10)
        }
        
        filterButton.imageEdgeInsets.right = 24
        filterButton.snp.makeConstraints { make in
            make.right.equalTo(self)
            make.width.equalTo(45 + 24)
            make.height.equalTo(32)
            make.bottom.equalTo(self).inset(10)
        }

        // Query once loaded
        self.onHeaderApply(action: .apply(SearchQuery()))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.hairlineShadow(height: 1.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchLocationButton: UIButton {
    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        
        self.contentEdgeInsets.top = 2
        self.imageEdgeInsets.left = 20
        
        self.setTitle("Singapore", for: .normal)
        self.setTitleColor(UIColor.black, for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)
        
        self.tintColor = UIColor.black
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchQueryLabel: UIButton {
    let field = SearchTextField()
    
    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        
        field.layer.cornerRadius = 4
        field.color = UIColor(hex: "2E2E2E")
        field.backgroundColor = UIColor.init(hex: "EBEBEB")
        
        field.leftImage = UIImage(named: "SC-Search-18")
        field.leftImagePadding = 1
        field.leftImageWidth = 32
        field.leftImageSize = 18
        
        field.placeholder = "Search any restaurant or cuisine"
        field.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        
        field.isEnabled = false
        
        self.addSubview(field)
        field.snp.makeConstraints { make in
            make.edges.equalTo(self)
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

// Scroll operations
extension SearchHeaderView {
    var maxHeight: CGFloat { return 108 }
    var minHeight: CGFloat { return 75 }
    var centerHeight: CGFloat { return (maxHeight - minHeight)/2 + minHeight }
    
    func contentDidScroll(scrollView: UIScrollView) {
        let height = calculateHeight(scrollView: scrollView)
        self.heightConstraint.layoutConstraints[0].constant = height
    }
    
    func calculateHeight(scrollView: UIScrollView) -> CGFloat {
        let y = scrollView.contentOffset.y
        if y <= -maxHeight {
            return maxHeight
        } else if y >= -minHeight {
            return minHeight
        } else {
            return Swift.abs(y)
        }
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
}

enum SearchHeaderAction {
    case apply(SearchQuery)
    case cancel // No Change
    case reset // Refresh Query
}

// Render search query functions
extension SearchHeaderView {
    func registerActions() {
        queryLabel.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)
        filterButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)
    }
    
    @objc func onHeaderAction(for view: UIView) {
        // TODO Pass SearchQuery On
        if view is SearchQueryLabel {
            controller.performSegue(withIdentifier: "SearchHeaderView_query", sender: self)
        } else if view is SearchFilterButton {
            controller.performSegue(withIdentifier: "SearchHeaderView_filter", sender: self)
        }
    }
    
    func onHeaderApply(action: SearchHeaderAction) {
        switch action {
        case .apply(let searchQuery):
            self.doQuery(searchQuery: searchQuery)
            return
        case .reset:
            doQuery(searchQuery: SearchQuery())
            return
        default:
            return
        }
    }
    
    private func doQuery(searchQuery: SearchQuery) {
        if MunchLocation.isEnabled {
            MunchLocation.waitFor(completion: { latLng, error in
                if let latLng = latLng {
                    var updatedQuery = searchQuery
                    updatedQuery.latLng = latLng
                    self.search(searchQuery: updatedQuery)
                } else if let error = error {
                    self.controller.alert(title: "Location Error", error: error)
                } else {
                    self.controller.alert(title: "Location Error", message: "No Error or Location Data")
                }
            })
        } else {
            self.search(searchQuery: searchQuery)
        }
    }
    
    private func search(searchQuery: SearchQuery) {
        self.searchQuery = searchQuery
        
        // Render to headerView & searchController
        self.render(searchQuery: searchQuery)
        self.controller.headerView(render: searchQuery)
    }
    
    private func render(searchQuery: SearchQuery) {
        if let location = searchQuery.location {
            self.locationButton.setTitle(location.name, for: .normal)
        } else if MunchLocation.isEnabled {
            self.locationButton.setTitle("Current Location", for: .normal)
        } else {
            self.locationButton.setTitle("Singapore", for: .normal)
        }
        
        self.queryLabel.field.text = searchQuery.query
    }
}

class HeaderViewSegue: UIStoryboardSegue {
    override func perform() {
        super.perform()
        let headerView = (source as! SearchController).headerView!
        if let navigation = destination as? UINavigationController {
            if let query = navigation.topViewController as? SearchQueryController {
                query.headerView = headerView
            } else if let filter = navigation.topViewController as? SearchFilterController {
                filter.headerView = headerView
            }
        }
    }
}
