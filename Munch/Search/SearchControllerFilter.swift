//
//  SearchControllerFilter.swift
//  Munch
//
//  Created by Fuxing Loh on 18/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import TTGTagCollectionView
import SnapKit

class SearchFilterController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var searchQuery: SearchQuery!

    let headerView = SearchFilterHeaderView()
    let tableView = UITableView()
    let applyView = SearchFilterApplyView()

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
        self.view.addSubview(tableView)
        self.view.addSubview(headerView)
        self.view.addSubview(applyView)
        self.makeConstraints()
        self.linkActions()

        self.applyView.searchQuery = searchQuery

        self.filterCells = [
            SearchFilterHourCell(applyView: self.applyView),
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
        self.tableView.contentInset.bottom = 12

    }

    private func makeConstraints() {
        headerView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view).inset(20)
            make.left.right.equalTo(self.view)
            make.height.equalTo(44)
        }

        tableView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.headerView.snp.bottom)
            make.bottom.equalTo(self.applyView.snp.top)
        }

        applyView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(self.view)
        }
    }

    private func linkActions() {
        self.headerView.cancelButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)
        self.applyView.applyBtn.addTarget(self, action: #selector(actionApply(_:)), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // To force auto layout
        self.tableView.reloadData()
    }

    @objc func actionCancel(_ sender: Any) {
        self.dismiss(animated: true)
    }

    @objc func actionApply(_ sender: Any) {
        self.searchQuery = applyView.searchQuery
        performSegue(withIdentifier: "unwindToSearchWithSegue", sender: self)
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

class SearchFilterHeaderView: UIView {
    let tagCollection = SearchFilterTagCollection()
    let titleView = UILabel()
    let cancelButton = UIButton()

    init() {
        super.init(frame: CGRect.zero)
        self.addSubview(titleView)
        self.addSubview(cancelButton)

        self.makeViews()
    }

    private func makeViews() {
        self.backgroundColor = .white
        titleView.text = "Filter"
        titleView.font = .systemFont(ofSize: 17, weight: .semibold)
        titleView.snp.makeConstraints { make in
            make.centerX.centerY.equalTo(self)
        }

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.black, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 15)
        cancelButton.titleEdgeInsets.right = 24
        cancelButton.contentHorizontalAlignment = .right
        cancelButton.snp.makeConstraints { make in
            make.width.equalTo(90)
            make.top.bottom.equalTo(self)
            make.right.equalTo(self)
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

class SearchFilterApplyView: UIView {
    let label = UILabel()
    let applyBtn = UIButton()

    var searchQuery: SearchQuery? {
        didSet {
            render()
        }
    }

    init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.white
        self.addSubview(label)
        self.addSubview(applyBtn)

        label.font = UIFont.systemFont(ofSize: 16, weight: .light)

        applyBtn.setTitle("Apply", for: .normal)
        applyBtn.setTitleColor(UIColor.primary, for: .normal)
        applyBtn.titleLabel!.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        applyBtn.contentHorizontalAlignment = .right
        applyBtn.titleEdgeInsets.right = 24

        makeConstraints()
    }

    private func makeConstraints() {
        label.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self)
            make.left.equalTo(self).inset(24)
            make.right.equalTo(applyBtn.snp.left)
        }

        applyBtn.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self)
            make.right.equalTo(self)
            make.width.equalTo(85)
        }

        self.snp.makeConstraints { (make) in
            make.height.equalTo(54)
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
        searchQuery?.filter.tag.positives = []
        searchQuery?.filter.hour.day = nil
        searchQuery?.filter.hour.time = nil
    }

    private func render() {
        if let searchQuery = searchQuery {
            var count = searchQuery.filter.tag.positives.count
            if searchQuery.filter.hour.day != nil {
                count += 1
            }
            label.text = "\(count) Selected Filters"
        } else {
            label.text = "0 Selected Filters"
        }
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
            applyView.searchQuery?.filter.hour.day = Place.Hour.Formatter.dayNow()

            if (tagText == "Open Now") {
                applyView.searchQuery?.filter.hour.time = formatter.string(from: Date())
                self.tagCollection.setTagAt(1, selected: false)
            } else if tagText == "After Midnight" {
                applyView.searchQuery?.filter.hour.time = "01:00"
                self.tagCollection.setTagAt(0, selected: false)
            }
        } else {
            applyView.searchQuery?.filter.hour.day = nil
            applyView.searchQuery?.filter.hour.time = nil
        }
    }

    override func contains(tag: String) -> Bool {
        if let time = applyView.searchQuery?.filter.hour.time {
            if tag == "After Midnight", time == "01:00" {
                return true
            } else if tag == "Open Now", time != "01:00" {
                return true
            }
        }
        return false
    }
}

class SearchFilterCuisineCell: SearchFilterTagCell {
    override var title: String {
        return "Cuisine"
    }

    override var tags: [String] {
        return ["African", "American", "Arabic", "Argentinean", "Asian", "Australian", "Bangladeshi", "Barbecue", "Beijing", "Belgian", "Brazilian", "Burmese", "Cambodian", "Cantonese", "Caribbean", "Chinese", "Cuban", "Desserts", "Dim Sum", "Dongbei", "Dutch", "English", "Eurasian", "European", "Foochow", "French", "Fruits", "Fujian", "Fusion", "German", "Greek", "Hainanese", "Hakka", "Hokkien", "Hong Kong", "Indian", "Indochinese", "International", "Iranian", "Irish", "Italian", "Japanese", "Korean", "Latin American", "Lebanese", "Malay Indonesian", "Mediterranean", "Mexican", "Middle Eastern", "Modern European", "Mongolian", "Moroccan", "Nonya Peranakan", "North Indian", "Others Asian", "Pakistani", "Pizza", "Portuguese", "Russian", "Seafood", "Shanghainese", "Sze chuan", "Singaporean", "Snacks", "South Indian", "Spanish", "Steak and Grills", "Steamboat", "Swiss", "Taiwanese", "Teochew", "Thai", "Turkish", "Vegetarian", "Vietnamese", "Western", "Zi Char"]
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
        self.addSubview(titleLabel)
        self.addSubview(tagCollection)

        titleLabel.text = self.title
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.8)

        tagCollection.addTags(self.tags)
        tagCollection.delegate = self
        tagCollection.defaultConfig.tagTextFont = UIFont.systemFont(ofSize: 13.0, weight: .regular)
        tagCollection.defaultConfig.tagTextColor = UIColor.black.withAlphaComponent(0.75)

        tagCollection.defaultConfig.tagBackgroundColor = UIColor.white
        tagCollection.defaultConfig.tagSelectedBackgroundColor = UIColor.primary

        tagCollection.defaultConfig.tagBorderWidth = 0.5
        tagCollection.defaultConfig.tagBorderColor = UIColor.black.withAlphaComponent(0.25)
        tagCollection.defaultConfig.tagShadowOffset = CGSize.zero
        tagCollection.defaultConfig.tagShadowRadius = 0

        tagCollection.defaultConfig.tagSelectedBorderWidth = 0.5
        tagCollection.defaultConfig.tagSelectedBorderColor = UIColor.primary

        tagCollection.defaultConfig.tagExtraSpace = CGSize(width: 21, height: 13)

        tagCollection.horizontalSpacing = 10
        tagCollection.contentInset = UIEdgeInsets.init(topBottom: 2, leftRight: 0)

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
            applyView.searchQuery?.filter.tag.positives.insert(tagText)
        } else {
            applyView.searchQuery?.filter.tag.positives.remove(tagText)
        }
    }

    func contains(tag: String) -> Bool {
        return applyView.searchQuery?.filter.tag.positives.contains(tag) ?? false
    }

    var title: String {
        return ""
    }

    var tags: [String] {
        return []
    }
}