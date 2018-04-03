//
//  SearchControllerSuggest.swift
//  Munch
//
//  Created by Fuxing Loh on 18/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import Firebase
import SnapKit
import SwiftyJSON
import TPKeyboardAvoiding

class DiscoverFilterRootController: UINavigationController, UINavigationControllerDelegate {
    init(searchQuery: SearchQuery, extensionDismiss: @escaping((SearchQuery?) -> Void)) {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [DiscoverFilterController(searchQuery: searchQuery, extensionDismiss: extensionDismiss)]
        self.delegate = self
    }

    // Fix bug when pop gesture is enabled for the root controller
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        self.interactivePopGestureRecognizer?.isEnabled = self.viewControllers.count > 1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class DiscoverFilterController: UIViewController {
    private let onExtensionDismiss: ((SearchQuery?) -> Void)
    let manager: DiscoverFilterControllerManager

    fileprivate let headerView = DiscoverFilterHeaderView()
    fileprivate let bottomView = DiscoverFilterBottomView()

    fileprivate let tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50

        tableView.tableFooterView = UIView(frame: CGRect.zero)

        tableView.contentInset.bottom = 14
        tableView.separatorStyle = .none
        return tableView
    }()

    private var results: [DiscoverFilterType]?
    private var searchQuery: SearchQuery
    private var state: State = State.filter {
        didSet {
            switch state {
            case .filter:
                self.tableView.reloadData()
            case .loading:
                self.results = nil
                self.tableView.reloadData()
            case .result:
                self.tableView.reloadData()
            }
        }
    }

    enum State {
        case filter
        case result
        case loading
    }

    init(searchQuery: SearchQuery, extensionDismiss: @escaping((SearchQuery?) -> Void)) {
        self.onExtensionDismiss = extensionDismiss
        self.searchQuery = searchQuery
        self.manager = .init(searchQuery: searchQuery)
        super.init(nibName: nil, bundle: nil)

        self.registerCell()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(tableView)
        self.view.addSubview(headerView)
        self.view.addSubview(bottomView)

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.headerView.controller = self

        self.headerView.closeButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)
        self.headerView.resetButton.addTarget(self, action: #selector(actionReset(_:)), for: .touchUpInside)
        self.bottomView.applyBtn.addTarget(self, action: #selector(actionApply(_:)), for: .touchUpInside)
        self.headerView.render(query: self.searchQuery)

        self.manager.addUpdateHook { query in
            // TODO Render
            self.headerView.render(query: query)
//            self.bottomView.render(searchQuery: query)

            if query != self.searchQuery {
                self.state = .filter
            } else {
                self.tableView.reloadData()
            }
        }

        self.headerView.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.left.right.equalTo(self.view)
        }

        self.bottomView.snp.makeConstraints { make in
            make.bottom.equalTo(self.view)
            make.left.right.equalTo(self.view)
        }

        self.tableView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.headerView.snp.bottom)
            make.bottom.equalTo(self.bottomView.snp.top)
        }

        self.tableView.layoutIfNeeded()
    }

    @objc func actionCancel(_ sender: Any) {
        self.onExtensionDismiss(nil)
        self.dismiss(animated: true)
    }

    @objc func actionReset(_ sender: Any) {
        self.manager.reset()
    }

    @objc func actionApply(_ sender: Any) {
        self.onExtensionDismiss(manager.searchQuery)
        self.dismiss(animated: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DiscoverFilterController: UITableViewDataSource, UITableViewDelegate {
    func registerCell() {
        tableView.register(DiscoverFilterCellDescription.self, forCellReuseIdentifier: DiscoverFilterCellDescription.id)
        tableView.register(DiscoverFilterCellHeader.self, forCellReuseIdentifier: DiscoverFilterCellHeader.id)
        tableView.register(DiscoverFilterCellHeaderLocation.self, forCellReuseIdentifier: DiscoverFilterCellHeaderLocation.id)
        tableView.register(DiscoverFilterCellLocation.self, forCellReuseIdentifier: DiscoverFilterCellLocation.id)
        tableView.register(DiscoverFilterCellTag.self, forCellReuseIdentifier: DiscoverFilterCellTag.id)
        tableView.register(DiscoverFilterCellTiming.self, forCellReuseIdentifier: DiscoverFilterCellTiming.id)
        tableView.register(DiscoverFilterCellNoResult.self, forCellReuseIdentifier: DiscoverFilterCellNoResult.id)
        tableView.register(DiscoverFilterCellLoading.self, forCellReuseIdentifier: DiscoverFilterCellLoading.id)
        tableView.register(DiscoverFilterCellPriceRange.self, forCellReuseIdentifier: DiscoverFilterCellPriceRange.id)
        tableView.register(DiscoverFilterCellTagMore.self, forCellReuseIdentifier: DiscoverFilterCellTagMore.id)
    }

    var items: [DiscoverFilterType] {
        switch self.state {
        case .loading:
            return [DiscoverFilterType.loading]
        case .filter:
            return self.manager.suggestions
        case .result:
            if let results = self.results {
                return results
            }
            return [DiscoverFilterType.loading]
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.row] {
        case .empty:
            return tableView.dequeueReusableCell(withIdentifier: DiscoverFilterCellNoResult.id) as! DiscoverFilterCellNoResult

        case .description:
            return tableView.dequeueReusableCell(withIdentifier: DiscoverFilterCellDescription.id) as! DiscoverFilterCellDescription

        case .loading:
            return tableView.dequeueReusableCell(withIdentifier: DiscoverFilterCellLoading.id) as! DiscoverFilterCellLoading

        case .header(let title):
            let cell = tableView.dequeueReusableCell(withIdentifier: DiscoverFilterCellHeader.id) as! DiscoverFilterCellHeader
            cell.render(title: title)
            return cell

        case .headerLocation:
            return tableView.dequeueReusableCell(withIdentifier: DiscoverFilterCellHeaderLocation.id) as! DiscoverFilterCellHeaderLocation

        case .location(let locations):
            let cell = tableView.dequeueReusableCell(withIdentifier: DiscoverFilterCellLocation.id) as! DiscoverFilterCellLocation
            cell.render(locations: locations, controller: self)
            return cell

        case .priceRange:
            let cell = tableView.dequeueReusableCell(withIdentifier: DiscoverFilterCellPriceRange.id) as! DiscoverFilterCellPriceRange
            cell.controller = self
            return cell

        case .tag(let tag):
            let cell = tableView.dequeueReusableCell(withIdentifier: DiscoverFilterCellTag.id) as! DiscoverFilterCellTag
            let text = tag.name ?? ""
            cell.render(title: text, selected: manager.isSelected(tag: text))
            return cell

        case .tagMore:
            return tableView.dequeueReusableCell(withIdentifier: DiscoverFilterCellTagMore.id) as! DiscoverFilterCellTagMore

        case .time(let timings):
            let cell = tableView.dequeueReusableCell(withIdentifier: DiscoverFilterCellTiming.id) as! DiscoverFilterCellTiming
            cell.render(timings: timings, controller: self)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch items[indexPath.row] {
        case .tag(let tag):
            let text = tag.name ?? ""
            manager.select(tag: text, selected: !manager.isSelected(tag: text))

        case .headerLocation:
            // TODO
            return

        case .tagMore(let title):
            // TODO
            return
        default: return
        }
    }
}

fileprivate class DiscoverFilterHeaderView: UIView, MunchTagCollectionViewDelegate {
    fileprivate var controller: DiscoverFilterController!
    fileprivate let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Filter"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.black.withAlphaComponent(0.75)
        return label
    }()
    fileprivate let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Search-Close"), for: .normal)
        button.tintColor = .black
        button.imageEdgeInsets.left = 18
        button.contentHorizontalAlignment = .left
        return button
    }()

    fileprivate let resetButton: UIButton = {
        let button = UIButton()
        button.setTitle("RESET", for: .normal)
        button.setTitleColor(UIColor(hex: "303030"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        button.titleEdgeInsets.right = 24
        button.contentHorizontalAlignment = .right
        button.backgroundColor = .white
        return button
    }()

    fileprivate let tagCollection: MunchTagCollectionView = {
        let view = MunchTagCollectionView()
        return view
    }()

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.backgroundColor = .white

        self.addSubview(titleLabel)
        self.addSubview(closeButton)
        self.addSubview(resetButton)
        self.addSubview(tagCollection)

        self.tagCollection.delegate = self

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.height.equalTo(44)
            make.centerX.equalTo(self)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.left.equalTo(self)

            make.width.equalTo(64)
            make.height.equalTo(44)
        }

        resetButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.right.equalTo(self)

            make.width.equalTo(84)
            make.height.equalTo(44)
        }

        tagCollection.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.height.equalTo(33)

            make.top.equalTo(titleLabel.snp.bottom)
            make.bottom.equalTo(self).inset(10)
        }
    }

    var tags: [FilterTagType] = []

    func render(query: SearchQuery) {
        tags = FilterTagView.resolve(query: query)
        self.tagCollection.removeAll()
        for tag in tags {
            switch tag {
            case .location(let text):
                self.tagCollection.add(type: .filterTag(text))
            case .hour(let text):
                self.tagCollection.add(type: .filterTagClose(text))
            case .tag(let text):
                self.tagCollection.add(type: .filterTagClose(text))
            case .price(let text):
                self.tagCollection.add(type: .filterTagClose(text))
            }
        }
    }

    func tagCollectionView(collectionView: MunchTagCollectionView, didSelect type: MunchTagCollectionType, index: Int) {
        switch tags[index] {
        case .location(let text):
            if text.lowercased() == "nearby" {
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Reset to Nearby", style: .destructive) { action in
                    self.controller.manager.select(location: nil)
                })
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                self.controller.present(alert, animated: true)
            }
        case .hour(let text):
            self.controller.manager.select(hour: text)
        case .tag(let text):
            self.controller.manager.reset(tags: [text])
        case .price:
            self.controller.manager.resetPrice()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: 2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class DiscoverFilterBottomView: UIView {
    fileprivate let applyBtn: UIButton = {
        let applyBtn = UIButton()
        applyBtn.layer.cornerRadius = 3
        applyBtn.backgroundColor = .primary
        applyBtn.setTitle("Loading...", for: .normal)
        applyBtn.setTitleColor(.white, for: .normal)
        applyBtn.titleLabel!.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return applyBtn
    }()

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.addSubview(applyBtn)

        applyBtn.snp.makeConstraints { (make) in
            make.top.equalTo(self).inset(12)
            make.bottom.equalTo(self.safeArea.bottom).inset(12)
            make.right.left.equalTo(self).inset(24)
            make.height.equalTo(46)
        }
    }

    // TODO self.applyBtn.setTitle(DiscoverFilterBottomView.countTitle(count: count), for: .normal)

    class func countTitle(count: Int, empty: String = "No Results", prefix: String = "See", postfix: String = "Restaurants") -> String {
        if count == 0 {
            return empty
        } else if count > 100 {
            return "\(prefix) 100+ \(postfix)"
        } else if count <= 10 {
            return "\(prefix) \(count) \(postfix)"
        } else {
            let rounded = count / 10 * 10
            return "\(prefix) \(rounded)+ \(postfix)"
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: -2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}