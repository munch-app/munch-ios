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
    let tabCollection: UICollectionView
    
    var heightConstraint: Constraint! = nil
    
    override init(frame: CGRect = CGRect()) {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        tabCollection = UICollectionView(frame: frame, collectionViewLayout: layout)
        
        super.init(frame: frame)
        tabCollection.delegate = self
        tabCollection.dataSource = self
        
        self.backgroundColor = UIColor.white
        self.addSubview(locationButton)
        self.addSubview(queryLabel)
        self.addSubview(filterButton)
        self.addSubview(tabCollection)
        
        let statusView = UIView()
        statusView.backgroundColor = UIColor.white
        self.addSubview(statusView)
        
        self.snp.makeConstraints { make in
            self.heightConstraint = make.height.equalTo(153).constraint
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
        
        queryLabel.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.right.equalTo(filterButton.snp.left)
            make.height.equalTo(32)
            make.bottom.equalTo(tabCollection.snp.top).inset(-3)
        }
        
        filterButton.snp.makeConstraints { make in
            make.right.equalTo(self).inset(24)
            make.width.equalTo(45)
            make.height.equalTo(32)
            make.bottom.equalTo(tabCollection.snp.top).inset(-3)
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
        
        self.contentEdgeInsets.top = 2
        self.imageEdgeInsets.left = 20
        
        self.setTitle("Singapore", for: .normal)
        self.setTitleColor(UIColor.black, for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFontWeightSemibold)
        
        self.setImage(UIImage(named: "icons8-Expand Arrow-20"), for: .normal)
        self.tintColor = UIColor.black
        self.semanticContentAttribute = .forceRightToLeft
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchQueryLabel: SearchTextField {
    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        
        self.layer.cornerRadius = 4
        self.color = UIColor(hex: "2E2E2E")
        self.backgroundColor = UIColor.init(hex: "EBEBEB")
        
        self.leftImage = UIImage(named: "SC-Search-18")
        self.leftImagePadding = 1
        self.leftImageWidth = 32
        self.leftImageSize = 18
        
        self.placeholder = "Search any restaurant or cuisine"
        self.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightRegular)
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
