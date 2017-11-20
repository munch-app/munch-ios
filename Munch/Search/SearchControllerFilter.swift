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
import BEMCheckBox

class SearchFilterController: UIViewController {
    var searchQuery: SearchQuery!

    fileprivate let headerView = SearchFilterHeaderView()
    fileprivate let tableView = UITableView()
    fileprivate let applyView = SearchFilterApplyView()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.applyView.render(searchQuery: searchQuery)
        self.tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()
        self.linkActions()
        self.registerCell()

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.applyView.render(searchQuery: searchQuery)
    }

    private func initViews() {
        view.addSubview(tableView)
        view.addSubview(headerView)
        view.addSubview(applyView)

        headerView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view)
            make.left.right.equalTo(self.view)
            make.height.equalTo(64)
        }

        tableView.separatorStyle = .none
        tableView.separatorInset.left = 24
        tableView.allowsSelection = true
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.sectionHeaderHeight = 44
        tableView.estimatedRowHeight = 50

        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 12))
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
        self.headerView.resetButton.addTarget(self, action: #selector(actionReset(_:)), for: .touchUpInside)
        self.applyView.applyBtn.addTarget(self, action: #selector(actionApply(_:)), for: .touchUpInside)
    }

    @objc func actionReset(_ sender: Any) {
        searchQuery?.filter.tag.positives = []
        searchQuery?.filter.hour.day = nil
        searchQuery?.filter.hour.time = nil
        self.applyView.render(searchQuery: searchQuery)
        self.tableView.reloadData()
    }

    @objc func actionCancel(_ sender: Any) {
        self.dismiss(animated: true)
    }

    @objc func actionApply(_ sender: Any) {
        performSegue(withIdentifier: "unwindToSearchWithSegue", sender: self)
    }
}

fileprivate enum SearchFilterType {
    case tag(String)
    case seeMore(String, [String])
}

extension SearchFilterController: UITableViewDataSource, UITableViewDelegate {
    private var items: [(String?, [SearchFilterType])] {
        return [
            // TODO Need to implement open now
            ("Timing", [SearchFilterType.tag("Breakfast"),
                        SearchFilterType.tag("Lunch"),
                        SearchFilterType.tag("Dinner"),
                        SearchFilterType.tag("Supper")]),
            ("Cuisine", [SearchFilterType.tag("Singaporean"),
                        SearchFilterType.tag("Japanese"),
                        SearchFilterType.tag("Italian"),
                        SearchFilterType.tag("Thai"),
                        SearchFilterType.tag("Chinese"),
                        SearchFilterType.tag("Korean"),
                        SearchFilterType.tag("Mexican"),
                        SearchFilterType.tag("Mediterranean"),
                        SearchFilterType.seeMore("Cuisine", [
                            "African",
                            "American",
                            "Arabic",
                            "Argentinean",
                            "Asian",
                            "Australian",
                            "Bangladeshi",
                            "Beijing",
                            "Belgian",
                            "Brazilian",
                            "Burmese",
                            "Cambodian",
                            "Cantonese",
                            "Caribbean",
                            "Chinese",
                            "Cuban",
                            "Dongbei",
                            "Dutch",
                            "English",
                            "Eurasian",
                            "European",
                            "Foochow",
                            "French",
                            "Fujian",
                            "Fusion",
                            "German",
                            "Greek",
                            "Hainanese",
                            "Hakka",
                            "Hokkien",
                            "Hong Kong",
                            "Indian",
                            "Indochinese",
                            "International",
                            "Iranian",
                            "Irish",
                            "Italian",
                            "Japanese",
                            "Korean",
                            "Latin American",
                            "Lebanese",
                            "Malay Indonesian",
                            "Mediterranean",
                            "Mexican",
                            "Middle Eastern",
                            "Modern European",
                            "Mongolian",
                            "Moroccan",
                            "Nonya Peranakan",
                            "North Indian",
                            "Pakistani",
                            "Portuguese",
                            "Russian",
                            "Shanghainese",
                            "Sze chuan",
                            "Singaporean",
                            "South Indian",
                            "Spanish",
                            "Swiss",
                            "Taiwanese",
                            "Teochew",
                            "Thai",
                            "Turkish",
                            "Vietnamese",
                            "Western",
                        ])]),
        ("Establishment", [SearchFilterType.tag("Bars & Pubs"),
                           SearchFilterType.tag("Hawker"),
                           SearchFilterType.tag("Café"),
                           SearchFilterType.tag("Snacks"),
                           SearchFilterType.seeMore("Establishment", [
                               "Bakery",
                               "Buffet",
                               "Café",
                               "Dessert",
                               "Fast Food",
                               "Hawker",
                               "Restaurant",
                               "High Tea",
                               "Drinks",
                               "Snacks",
                           ])]),
        ("Amenities", [SearchFilterType.tag("Child-Friendly"),
                       SearchFilterType.tag("Halal"),
                       SearchFilterType.tag("Large Group"),
                       SearchFilterType.tag("Pet-Friendly"),
                       SearchFilterType.seeMore("Amenities", [
                           "Child-Friendly",
                           "Vegetarian-Friendly",
                           "Healthy",
                           "Pet-Friendly",
                           "Halal",
                           "Large Group",
                       ])]),
        ("Occasion", [SearchFilterType.tag("Brunch"),
                      SearchFilterType.tag("Romantic"),
                      SearchFilterType.tag("Business Meal"),
                      SearchFilterType.tag("Football Screening"),
                      SearchFilterType.seeMore("Occasion", [
                          "Brunch",
                          "Romantic",
                          "Business Meal",
                          "Supper",
                      ])])
        ]
    }

    func registerCell() {
        tableView.register(SearchFilterTagCell.self, forCellReuseIdentifier: SearchFilterTagCell.id)
        tableView.register(SearchFilterTagMoreCell.self, forCellReuseIdentifier: SearchFilterTagMoreCell.id)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].1.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return items[section].0
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.tintColor = .white
        header.textLabel!.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.medium)
        header.textLabel!.textColor = UIColor.black.withAlphaComponent(0.85)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.section].1[indexPath.row]
        let selectedTags = self.searchQuery.filter.tag.positives

        switch item {
        case let .tag(tag):
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchFilterTagCell.id) as! SearchFilterTagCell
            cell.render(title: tag, selected: selectedTags.contains(tag))
            return cell
        case let .seeMore(name, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchFilterTagMoreCell.id) as! SearchFilterTagMoreCell
            cell.render(text: "More \(name)")
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.section].1[indexPath.row]

        switch item {
        case let .tag(tag):
            if let cell = tableView.cellForRow(at: indexPath) as? SearchFilterTagCell {
                tableView.beginUpdates()
                if (cell.flip()) {
                    self.searchQuery.filter.tag.positives.insert(tag)
                } else {
                    self.searchQuery.filter.tag.positives.remove(tag)
                }
                tableView.endUpdates()
                self.applyView.render(searchQuery: searchQuery)
            }
        case let .seeMore(name, tags):
            let controller = SearchFilterMoreController()
            controller.seeMore = (name, tags.sorted())
            controller.searchQuery = searchQuery
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
}

fileprivate class SearchFilterHeaderView: UIView {
    fileprivate let resetButton = UIButton()
    fileprivate let titleView = UILabel()
    fileprivate let cancelButton = UIButton()

    init() {
        super.init(frame: CGRect.zero)
        self.addSubview(resetButton)
        self.addSubview(titleView)
        self.addSubview(cancelButton)

        self.makeViews()
    }

    private func makeViews() {
        self.backgroundColor = .white

        resetButton.setTitle("RESET", for: .normal)
        resetButton.setTitleColor(UIColor.black.withAlphaComponent(0.7), for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        resetButton.titleEdgeInsets.left = 24
        resetButton.contentHorizontalAlignment = .left
        resetButton.snp.makeConstraints { make in
            make.top.equalTo(self).inset(20)
            make.bottom.equalTo(self)
            make.width.equalTo(90)
            make.left.equalTo(self)
        }

        titleView.text = "Filters"
        titleView.font = .systemFont(ofSize: 17, weight: .regular)
        titleView.textAlignment = .center
        titleView.snp.makeConstraints { make in
            make.top.equalTo(self).inset(20)
            make.bottom.equalTo(self)
            make.left.equalTo(resetButton.snp.right)
            make.right.equalTo(cancelButton.snp.left)
        }

        cancelButton.setTitle("CANCEL", for: .normal)
        cancelButton.setTitleColor(UIColor.black.withAlphaComponent(0.7), for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        cancelButton.titleEdgeInsets.right = 24
        cancelButton.contentHorizontalAlignment = .right
        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(self).inset(20)
            make.bottom.equalTo(self)
            make.width.equalTo(90)
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

fileprivate class SearchFilterApplyView: UIView {
    fileprivate let applyBtn = UIButton()
    fileprivate var searchQuery: SearchQuery!

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        initViews()
    }

    private func initViews() {
        self.backgroundColor = UIColor.white
        self.addSubview(applyBtn)

        applyBtn.layer.cornerRadius = 3
        applyBtn.backgroundColor = .primary
        applyBtn.setTitle("Loading...", for: .normal)
        applyBtn.setTitleColor(.white, for: .normal)
        applyBtn.titleLabel!.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        applyBtn.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self).inset(12)
            make.right.left.equalTo(self).inset(24)
        }

        self.snp.makeConstraints { (make) in
            make.height.equalTo(70)
        }
    }

    func render(searchQuery: SearchQuery) {
        self.searchQuery = searchQuery
        applyBtn.setTitle("Loading...", for: .normal)
        self.perform(#selector(renderDidCommit(_:)), with: nil, afterDelay: 0.5)
    }

    @objc fileprivate func renderDidCommit(_ sender: Any) {
        MunchApi.search.count(query: searchQuery, callback: { (meta, count) in
            if let count = count {
                if count == 0 {
                    self.applyBtn.setTitle("No result", for: .normal)
                } else if count > 100 {
                    self.applyBtn.setTitle("See 100+ places", for: .normal)
                } else if count <= 10 {
                    self.applyBtn.setTitle("See \(count) places", for: .normal)
                } else {
                    let rounded = count / 10 * 10
                    self.applyBtn.setTitle("See \(rounded)+ places", for: .normal)
                }
            }
        })
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.hairlineShadow(height: -1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class SearchFilterTagCell: UITableViewCell {
    let titleLabel = UILabel()
    let checkButton = BEMCheckBox(frame: CGRect(x: 0, y: 0, width: 30, height: 30))

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(titleLabel)
        self.addSubview(checkButton)

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.regular)
        titleLabel.textColor = .black
        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self).inset(12)
            make.left.equalTo(self).inset(24)
            make.right.equalTo(checkButton.snp.left).inset(-12)
        }

        checkButton.snp.makeConstraints { make in
            make.top.bottom.equalTo(self).inset(9)
            make.right.equalTo(self).inset(24)
        }
        checkButton.lineWidth = 1.5
        checkButton.tintColor = UIColor.black.withAlphaComponent(0.6)
        checkButton.onCheckColor = .primary
        checkButton.onTintColor = .primary
        checkButton.animationDuration = 0.25
        checkButton.isEnabled = false
    }

    func render(title: String, selected: Bool) {
        titleLabel.text = title
        checkButton.setOn(selected, animated: false)
    }

    /**
     Flip the switch on check button
     */
    func flip() -> Bool {
        let flip = !checkButton.on
        checkButton.setOn(flip, animated: true)
        return flip
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "SearchFilterTagCell"
    }
}

fileprivate class SearchFilterTagMoreCell: UITableViewCell {
    let titleLabel = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(titleLabel)
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.regular)
        titleLabel.textColor = .primary600
        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self).inset(12)
            make.left.right.equalTo(self).inset(24)
        }
    }

    func render(text: String) {
        titleLabel.text = text
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "SearchFilterTagMoreCell"
    }
}

fileprivate class SearchFilterMoreController: UIViewController, UIGestureRecognizerDelegate {
    var searchQuery: SearchQuery!
    var seeMore: (String, [String])!

    let headerView = SearchFilterHeaderView()
    let tableView = UITableView()
    let applyView = SearchFilterMoreApplyView()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()
        self.linkActions()
        self.registerCell()

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.applyView.render(searchQuery: searchQuery)
        self.headerView.titleView.text = seeMore.0
    }

    private func initViews() {
        view.addSubview(tableView)
        view.addSubview(headerView)
        view.addSubview(applyView)

        headerView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view)
            make.left.right.equalTo(self.view)
            make.height.equalTo(64)
        }

        tableView.separatorStyle = .none
        tableView.separatorInset.left = 24
        tableView.allowsSelection = true
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.sectionHeaderHeight = 44
        tableView.estimatedRowHeight = 50

        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 12))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 12))
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
        self.headerView.resetButton.addTarget(self, action: #selector(actionReset(_:)), for: .touchUpInside)
        self.applyView.applyBtn.addTarget(self, action: #selector(actionApply(_:)), for: .touchUpInside)
    }

    @objc func actionReset(_ sender: Any) {
        for tag in seeMore.1 {
            searchQuery.filter.tag.positives.remove(tag)
        }
        self.applyView.render(searchQuery: searchQuery)
        self.tableView.reloadData()
    }

    @objc func actionCancel(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    @objc func actionApply(_ sender: Any) {
        // On cancel, update previous filter view
        if let count = navigationController?.viewControllers.count,
           let filter = navigationController?.viewControllers[count - 2] as? SearchFilterController {
            filter.searchQuery = self.searchQuery
        }
        self.navigationController?.popViewController(animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

fileprivate class SearchFilterMoreApplyView: SearchFilterApplyView {
    fileprivate override func renderDidCommit(_ sender: Any) {
        MunchApi.search.count(query: searchQuery, callback: { (meta, count) in
            if let count = count {
                if count == 0 {
                    self.applyBtn.setTitle("No result", for: .normal)
                } else if count > 100 {
                    self.applyBtn.setTitle("Apply (100+ places)", for: .normal)
                } else if count <= 10 {
                    self.applyBtn.setTitle("Apply (\(count) places)", for: .normal)
                } else {
                    let rounded = count % 10 * 10
                    self.applyBtn.setTitle("Apply (\(rounded)+ places)", for: .normal)
                }
            }
        })
    }
}

extension SearchFilterMoreController: UITableViewDataSource, UITableViewDelegate {
    func registerCell() {
        tableView.register(SearchFilterTagCell.self, forCellReuseIdentifier: SearchFilterTagCell.id)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return seeMore.1.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let selectedTags = self.searchQuery.filter.tag.positives
        let tag = seeMore.1[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: SearchFilterTagCell.id) as! SearchFilterTagCell
        cell.render(title: tag, selected: selectedTags.contains(tag))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let tag = seeMore.1[indexPath.row]

        if let cell = tableView.cellForRow(at: indexPath) as? SearchFilterTagCell {
            tableView.beginUpdates()
            if (cell.flip()) {
                self.searchQuery.filter.tag.positives.insert(tag)
            } else {
                self.searchQuery.filter.tag.positives.remove(tag)
            }
            tableView.endUpdates()
            self.applyView.render(searchQuery: searchQuery)
        }
    }
}