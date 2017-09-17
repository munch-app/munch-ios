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
}

protocol SearchHeaderDelegate {
    
    /**
    When collectManager is nil means that the value is loading
     */
    func headerView(render collectionManager: SearchCollectionManager?)
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
    let tabCollection = SearchTabCollection()

    var heightConstraint: Constraint! = nil
    
    var collectionManagers = [SearchCollectionManager]()
    var selectedTab = 0
    
    init(controller: SearchController) {
        super.init(frame: CGRect())
        self.controller = controller
        
        self.tabCollection.delegate = self
        self.tabCollection.dataSource = self
        
        self.backgroundColor = UIColor.white
        
        self.addSubview(locationButton)
        self.addSubview(queryLabel)
        self.addSubview(filterButton)
        self.addSubview(tabCollection)
        
        registerCell()
        
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
        
        // Query once loaded
        self.query()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.hairlineShadow(height: 1.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var searchQuery = SearchQuery()
    
    func query() {
        MunchApi.search.collections(query: searchQuery) { meta, collections in
            if (meta.isOk()) {
                self.collectionManagers = collections.map { SearchCollectionManager(collection: $0) }
                if MunchLocation.isEnabled {
                    self.collectionManagers.get(0)?.topCards.append(SearchStaticNoLocationCard.card)
                }
                
                self.tabCollection.reloadData()
                self.controller.headerView(render: self.collectionManagers.get(0))
            } else {
                self.controller.present(meta.createAlert(), animated: true)
            }
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

class SearchTabCollection: UICollectionView {
    init(frame: CGRect = CGRect()) {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 150, height: 50)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset.left = 24
        layout.scrollDirection = .horizontal
        super.init(frame: frame, collectionViewLayout: layout)
        
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.backgroundColor = UIColor.white
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchTabNameCell: UICollectionViewCell {
    static let titleFont = UIFont.systemFont(ofSize: 12, weight: UIFontWeightSemibold)
    
    let label = UILabel()
    let indicator = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.label.font = SearchTabNameCell.titleFont
        self.addSubview(label)
        self.addSubview(indicator)
        
        label.snp.makeConstraints { make in
            make.top.bottom.left.equalTo(self)
            make.right.equalTo(self).inset(24)
        }
        
        indicator.snp.makeConstraints { make in
            make.left.bottom.equalTo(self)
            make.right.equalTo(self).inset(24)
            make.height.equalTo(2)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(title: String, selected: Bool) {
        self.label.text = title.uppercased()
        if selected {
            label.textColor = UIColor.black.withAlphaComponent(0.85)
            indicator.backgroundColor = .primary300
        } else {
            label.textColor = UIColor.black.withAlphaComponent(0.35)
            indicator.backgroundColor = .white
        }
    }
    
    class func width(title: String) -> CGSize {
        let width = UILabel.textWidth(font: titleFont, text: title.uppercased())
        return CGSize(width: width + 24, height: 50)
    }
}

class SearchTabShimmerCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let label = ShimmerView()
        label.shimmeringSpeed = 80
        self.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.left.equalTo(self)
            make.right.equalTo(self).inset(24)
            
            make.topMargin.bottomMargin.equalTo(self).inset(14)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func width() -> CGSize {
        return CGSize(width: 90, height: 50)
    }
}

extension SearchHeaderView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func registerCell() {
        tabCollection.register(SearchTabShimmerCell.self, forCellWithReuseIdentifier: "SearchTabShimmerCell")
        tabCollection.register(SearchTabNameCell.self, forCellWithReuseIdentifier: "SearchTabNameCell")
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (collectionManagers.isEmpty) {
            return 5
        } else {
            return collectionManagers.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if (collectionManagers.isEmpty) {
            return SearchTabShimmerCell.width()
        } else {
            let title = collectionManagers[indexPath.row].name
            return SearchTabNameCell.width(title: title)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if (collectionManagers.isEmpty) {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "SearchTabShimmerCell", for: indexPath)
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchTabNameCell", for: indexPath) as! SearchTabNameCell
            let title = collectionManagers[indexPath.row].name
            cell.render(title: title, selected: selectedTab == indexPath.row)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (!collectionManagers.isEmpty) {
            self.selectedTab = indexPath.row
            collectionView.reloadData()
            self.controller.headerView(render: collectionManagers[indexPath.row])
        }
    }
}

// Scroll operations
extension SearchHeaderView {
    var maxHeight: CGFloat { return 153 }
    var minHeight: CGFloat { return 70 }
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

// Render search query functions
extension SearchHeaderView {
    func render() {
        // Update changes in the search query
    }
}
