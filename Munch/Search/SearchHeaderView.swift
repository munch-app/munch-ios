//
//  SearchHeaderView.swift
//  Munch
//
//  Created by Fuxing Loh on 16/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

enum SearchHeaderAction {
    case location
    case query
    case filter
    case tab(Int)
}

protocol SearchHeaderDelegate {
    func searchHeader(didSelect: SearchHeaderAction)
}

class SearchHeaderView: UIView {
    let locationButton = SearchLocationButton()
    let queryLabel = SearchQueryLabel()
    let filterButton = SearchFilterButton()
    let tabCollection = UICollectionView()
    
    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        tabCollection.delegate = self
        tabCollection.dataSource = self
        
        self.addSubview(locationButton)
        self.addSubview(queryLabel)
        self.addSubview(filterButton)
        self.addSubview(tabCollection)
        
        let statusView = UIView()
        self.addSubview(statusView)
        
        statusView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self)
            make.height.equalTo(20)
        }

        locationButton.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.height.equalTo(45)
            make.bottom.equalTo(queryLabel.snp.top)
        }
        
        queryLabel.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.right.equalTo(filterButton.snp.right)
            make.height.equalTo(32)
            make.bottom.equalTo(tabCollection.snp.top).inset(3)
        }
        
        filterButton.snp.makeConstraints { make in
            make.right.equalTo(self).inset(24)
            make.width.equalTo(45)
            make.height.equalTo(32)
            make.bottom.equalTo(tabCollection.snp.top).inset(3)
        }
        
        tabCollection.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(self)
            make.height.equalTo(50)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var searchQuery: SearchQuery = SearchQuery() {
        didSet {
            // TODO Render search bar again
        }
    }
}

class SearchLocationButton: UIButton {
    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchQueryLabel: UILabel {
    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchFilterButton: UIButton {
    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchHeaderView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}

// Scroll operations
extension SearchHeaderView {
    func scroll() {
        // 153 = Max
        // 70 = Min
    }
    
    func scrollDidEnd() {
        
    }
}

// Apply and Reset functions for navigation bar
extension SearchHeaderView {
    
}
