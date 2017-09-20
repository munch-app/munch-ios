//
//  SearchFilterController.swift
//  Munch
//
//  Created by Fuxing Loh on 18/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import TTGTagCollectionView

class SearchFilterController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    var applyView: SearchFilterApplyView!
    var headerView: SearchHeaderView!
    var filterCells: [SearchFilterTagCell]!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.applyView = SearchFilterApplyView(controller: self, searchQuery: headerView.mainSearchQuery)
        self.view.addSubview(applyView)
        applyView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(self.view)
        }
        
        self.filterCells = [
            SearchFilterHourCell(applyView: self.applyView),
            SearchFilterNeighbourhoodCell(applyView: self.applyView),
            SearchFilterCuisineCell(applyView: self.applyView),
            SearchFilterOccasionCell(applyView: self.applyView),
            SearchFilterEstablishmentCell(applyView: self.applyView),
        ]
        
        self.tableView.separatorStyle = .none
        self.tableView.allowsSelection = false
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 50
        
        let footerView = UIView(frame: CGRect.zero)
        self.tableView.tableFooterView = footerView
        self.tableView.contentInset.top = 10
        self.tableView.contentInset.bottom = applyView.height + 12
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // To force auto layout
        self.tableView.reloadData()
    }
    
    @IBAction func actionCancel(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @objc func actionApply(_ sender: Any) {
        self.dismiss(animated: true) {
            self.headerView.onHeaderApply(action: .apply(self.applyView.searchQuery))
        }
    }
}

extension SearchFilterController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterCells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = filterCells[indexPath.row]
        cell.layoutIfNeeded()
        cell.setNeedsDisplay()
        return cell
    }
}

class SearchFilterHourCell: SearchFilterTagCell {
    let formatter = DateFormatter()
    
    override init(applyView: SearchFilterApplyView) {
        super.init(applyView: applyView)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var title: String {
        return "Opening Hour"
    }
    
    override var tags: [String] {
        return ["Open Now", "After Midnight"]
    }
    
    override func textTagCollectionView(_ textTagCollectionView: TTGTextTagCollectionView!, didTapTag tagText: String!, at index: UInt, selected: Bool) {
        if selected {
            applyView.searchQuery.filter.hour.day = Place.Hour.Formatter.dayNow()
            
            if (tagText == "Open Now") {
                applyView.searchQuery.filter.hour.time = "01:00"
                self.tagCollection.setTagAt(1, selected: false)
            } else if tagText == "After Midnight" {
                applyView.searchQuery.filter.hour.time = formatter.string(from: Date())
                self.tagCollection.setTagAt(0, selected: false)
            }
        } else {
            applyView.searchQuery.filter.hour.day = nil
            applyView.searchQuery.filter.hour.time = nil
        }
    }
    
    override func contains(tag: String) -> Bool {
        if let time = applyView.searchQuery.filter.hour.time {
            if tag == "After Midnight", time == "01:00" {
                return true
            } else if tag == "Open Now", time != "01:00" {
                return true
            }
        }
        return false
    }
}

class SearchFilterNeighbourhoodCell: SearchFilterTagCell {
    override var title: String {
        return "Neighbourhood"
    }
    
    override var tags: [String] {
        return ["Bishan", "Toa Payoh"]
    }
}

class SearchFilterCuisineCell: SearchFilterTagCell {
    override var title: String {
        return "Cuisine"
    }
    
    override var tags: [String] {
        return ["African", "American", "Arabic", "Argentinean", "Asian", "Australian", "Bangladeshi", "Barbecue", "Beijing", "Belgian", "Brazilian", "Burmese", "Cambodian", "Cantonese", "Caribbean", "Chinese", "Cuban", "Desserts", "Dim Sum", "Dongbei", "Dutch", "English", "Eurasian", "European", "Foochow", "French", "Fruits", "Fujian", "Fusion","German", "Greek", "Hainanese", "Hakka", "Hokkien", "Hong Kong", "Indian", "Indochinese", "International", "Iranian", "Irish", "Italian", "Japanese", "Korean", "Latin American", "Lebanese", "Malay Indonesian", "Mediterranean", "Mexican", "Middle Eastern", "Modern European", "Mongolian", "Moroccan", "Nonya Peranakan", "North Indian", "Others Asian", "Pakistani", "Pizza", "Portuguese", "Russian", "Seafood", "Shanghainese","Sze chuan", "Singaporean","Snacks", "South Indian", "Spanish", "Steak and Grills", "Steamboat", "Swiss", "Taiwanese", "Teochew", "Thai", "Turkish", "Vegetarian", "Vietnamese", "Western", "Zi Char"]
    }
}

class SearchFilterOccasionCell: SearchFilterTagCell {
    override var title: String {
        return "Occasion"
    }
    
    override var tags: [String] {
        return ["Brunch", "After Work", "Birthdays", "Guys Night Out", "Business Meal", "Budget", "Great to hang", "Great for dates", "Dinner", "Football Screening", "Large Group", "Lunch", "Ladies Night", "Private Dining", "People Watching", "Scenic View", "Supper"]
    }
}

class SearchFilterEstablishmentCell: SearchFilterTagCell {
    override var title: String {
        return "Establishment"
    }
    
    override var tags: [String] {
        return ["Restaurant", "Bakery", "Bars & Pubs", "BBQ", "Bistro", "Buffet", "Coffeeshop", "Café", "Cafe", "Dessert", "Family", "Fast Food", "Fine Dining", "Franchise", "Hawker", "High Tea", "Steamboat"]
    }
}

class SearchFilterTagCell: UITableViewCell, TTGTextTagCollectionViewDelegate {
    let titleLabel = UILabel()
    let tagCollection = TTGTextTagCollectionView()
    
    var applyView: SearchFilterApplyView!
    
    init(applyView: SearchFilterApplyView) {
        super.init(style: .default, reuseIdentifier: nil)
        self.applyView = applyView
        
        titleLabel.text = self.title
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        self.addSubview(titleLabel)
        
        tagCollection.addTags(self.tags)
        tagCollection.delegate = self
        tagCollection.defaultConfig.tagTextFont = UIFont.systemFont(ofSize: 14.0, weight: .regular)
        tagCollection.defaultConfig.tagTextColor = UIColor.black.withAlphaComponent(0.7)
        
        tagCollection.defaultConfig.tagBackgroundColor = UIColor.white
        tagCollection.defaultConfig.tagSelectedBackgroundColor = UIColor.primary
        
        tagCollection.defaultConfig.tagBorderWidth = 0
        tagCollection.defaultConfig.tagSelectedBorderWidth = 0
        
        tagCollection.defaultConfig.tagShadowOffset = CGSize(width: 1, height: 1)
        tagCollection.defaultConfig.tagShadowRadius = 1
        self.addSubview(tagCollection)
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self).inset(0)
            make.left.right.equalTo(self).inset(24)
            make.height.equalTo(36)
        }
        
        tagCollection.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(24)
            make.top.equalTo(titleLabel.snp.bottom)
            make.bottom.equalTo(self).inset(8)
        }
        
        // Set tags to selected
        for (index, tag) in tags.enumerated() {
            if (contains(tag: tag)) {
                self.tagCollection.setTagAt(UInt(index), selected: true)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textTagCollectionView(_ textTagCollectionView: TTGTextTagCollectionView!, didTapTag tagText: String!, at index: UInt, selected: Bool) {
        if selected {
            applyView.searchQuery.filter.tag.positives.insert(tagText)
        } else {
            applyView.searchQuery.filter.tag.positives.remove(tagText)
        }
    }
    
    func contains(tag: String) -> Bool {
        return applyView.searchQuery.filter.tag.positives.contains(tag)
    }
    
    var title: String {
        return ""
    }
    
    var tags: [String] {
        return []
    }
}

class SearchFilterApplyView: UIView {
    let label = UILabel()
    let resetBtn = UIButton()
    let applyBtn = UIButton()

    var searchQuery: SearchQuery! {
        didSet {
            render()
        }
    }
    let height: CGFloat = 54
    
    init(controller: SearchFilterController, searchQuery: SearchQuery) {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.white
        self.searchQuery = searchQuery
        render()
        
        resetBtn.addTarget(self, action: #selector(reset), for: .touchUpInside)
        applyBtn.addTarget(controller, action: #selector(controller.actionApply(_:)), for: .touchUpInside)
        
        label.font = UIFont.systemFont(ofSize: 16, weight: .light)
        self.addSubview(label)
        
        resetBtn.setTitle("Reset", for: .normal)
        resetBtn.setTitleColor(UIColor.black.withAlphaComponent(0.6), for: .normal)
        resetBtn.titleLabel!.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        resetBtn.contentHorizontalAlignment = .right
        self.addSubview(resetBtn)
        
        applyBtn.setTitle("Apply", for: .normal)
        applyBtn.setTitleColor(UIColor.primary, for: .normal)
        applyBtn.titleLabel!.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        applyBtn.contentHorizontalAlignment = .right
        applyBtn.titleEdgeInsets.right = 24
        self.addSubview(applyBtn)
        makeConstraints()
    }
    
    private func makeConstraints() {
        label.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self)
            make.left.equalTo(self).inset(24)
            make.right.equalTo(resetBtn.snp.left)
        }
        
        resetBtn.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self)
            make.width.equalTo(70)
            make.right.equalTo(applyBtn.snp.left)
        }
        
        applyBtn.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self)
            make.right.equalTo(self)
            make.width.equalTo(85)
        }
        
        self.snp.makeConstraints { (make) in
            make.height.equalTo(self.height)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.hairlineShadow(height: -1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func reset() {
        searchQuery.filter.tag.positives = []
        searchQuery.filter.hour.day = nil
        searchQuery.filter.hour.time = nil
    }
    
    private func render() {
        var count = searchQuery.filter.tag.positives.count
        if searchQuery.filter.hour.day != nil { count += 1 }
        label.text = "\(count) Selected Filters"
    }
}


