//
// Created by Fuxing Loh on 21/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

import Firebase
import SnapKit
import NVActivityIndicatorView


class SearchFilterRootController: UINavigationController, UINavigationControllerDelegate {
    init(searchQuery: SearchQuery, extensionDismiss: @escaping((SearchQuery?) -> Void)) {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [SearchFilterController(searchQuery: searchQuery, extensionDismiss: extensionDismiss)]
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

class SearchFilterController: UIViewController {
    private let onExtensionDismiss: ((SearchQuery?) -> Void)
    private let manager: SearchFilterManager
    private let disposeBag = DisposeBag()

    private var items: [SearchFilterType] = []

    fileprivate let headerView = SearchFilterHeaderView()
    fileprivate let bottomView = SearchFilterBottomView()

    fileprivate var cellLocation: SearchFilterCellLocation!
    fileprivate var cellPriceRange: SearchFilterCellPriceRange!
    fileprivate var cellTagCategory: SearchFilterCellTagCategory!
    fileprivate var cellTiming: SearchFilterCellTiming!

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50

        tableView.tableFooterView = UIView(frame: CGRect.zero)

        tableView.contentInset.bottom = 16
        tableView.separatorStyle = .none
        return tableView
    }()

    init(searchQuery: SearchQuery, extensionDismiss: @escaping((SearchQuery?) -> Void)) {
        self.onExtensionDismiss = extensionDismiss
        self.manager = SearchFilterManager(searchQuery: searchQuery)
        super.init(nibName: nil, bundle: nil)

        self.registerCells()
        self.registerActions()
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

        self.headerView.render(query: self.manager.searchQuery)
        self.bottomView.render(count: nil)

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

        self.manager.observe()
                .debounce(0.1, scheduler: MainScheduler.instance)
                .catchError { (error: Error) in
                    self.alert(error: error)
                    return Observable.empty()
                }
                .subscribe { event in
                    switch event {
                    case .next(let items):
                        self.items = items
                        self.tableView.reloadData()
                        self.headerView.render(query: self.manager.searchQuery)
                        self.bottomView.render(count: self.manager.filterCount?.count)
                    case .error(let error):
                        self.alert(error: error)
                    case .completed:
                        return
                    }
                }.disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Actions
extension SearchFilterController: MunchTagCollectionViewDelegate {
    func registerActions() {
        self.headerView.closeButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)
        self.headerView.resetButton.addTarget(self, action: #selector(actionReset(_:)), for: .touchUpInside)
        self.bottomView.applyBtn.addTarget(self, action: #selector(actionApply(_:)), for: .touchUpInside)

        self.headerView.tagCollection.delegate = self
    }

    @objc func actionCancel(_ sender: Any) {
        self.onExtensionDismiss(nil)
        self.dismiss(animated: true)

        Analytics.logEvent("search_filter_action", parameters: [
            AnalyticsParameterItemCategory: "click_cancel" as NSObject
        ])
    }

    @objc func actionReset(_ sender: Any) {
        self.manager.reset()

        Analytics.logEvent("search_filter_action", parameters: [
            AnalyticsParameterItemCategory: "click_reset" as NSObject
        ])
    }

    @objc func actionApply(_ sender: Any) {
        self.onExtensionDismiss(manager.searchQuery)
        self.dismiss(animated: true)

        Analytics.logEvent("search_filter_action", parameters: [
            AnalyticsParameterItemCategory: "click_apply" as NSObject
        ])
    }

    func tagCollectionView(collectionView: MunchTagCollectionView, didSelect type: MunchTagCollectionType, index: Int) {
        switch self.headerView.tags[index] {
        case .location(let text):
            if text.lowercased() == "nearby" {
                return
            }

            self.manager.select(area: nil, persist: false)
            Analytics.logEvent("search_filter_action", parameters: [
                AnalyticsParameterItemCategory: "click_reset_location" as NSObject
            ])

        case .hour:
            self.manager.resetTiming()
            Analytics.logEvent("search_filter_action", parameters: [
                AnalyticsParameterItemCategory: "click_reset_hour" as NSObject
            ])

        case .tag(let tag):
            guard UserSetting.allow(remove: tag, controller: self) else {
                return
            }

            self.manager.reset(tags: [tag])
            Analytics.logEvent("search_filter_action", parameters: [
                AnalyticsParameterItemCategory: "click_reset_tag" as NSObject
            ])

        case .price:
            self.manager.resetPrice()
            Analytics.logEvent("search_filter_action", parameters: [
                AnalyticsParameterItemCategory: "click_reset_price" as NSObject
            ])
        }
    }
}

// MARK: TableView Cells
extension SearchFilterController: UITableViewDataSource, UITableViewDelegate {
    func registerCells() {
        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.cellLocation = SearchFilterCellLocation(manager: self.manager, controller: self)
        self.cellPriceRange = SearchFilterCellPriceRange(manager: self.manager, controller: self)
        self.cellTagCategory = SearchFilterCellTagCategory(manager: self.manager, controller: self)
        self.cellTiming = SearchFilterCellTiming(manager: self.manager, controller: self)

        func register(cellClass: UITableViewCell.Type) {
            tableView.register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
        }

        register(cellClass: SearchFilterCellTag.self)
        register(cellClass: SearchFilterCellTagMore.self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.row] {
        case .rowLocation: return cellLocation
        case .rowPrice: return cellPriceRange
        case .rowTime: return cellTiming
        case .cellCategory: return cellTagCategory

        case .cellTag:
            return tableView.dequeueReusableCell(withIdentifier: String(describing: SearchFilterCellTag.self)) as! SearchFilterCellTag

        case .cellTagMore:
            return tableView.dequeueReusableCell(withIdentifier: String(describing: SearchFilterCellTagMore.self)) as! SearchFilterCellTagMore
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch items[indexPath.row] {
        case .rowLocation(let locations):
            let cell = cell as! SearchFilterCellLocation
            cell.render(locations: locations)

        case .rowPrice(let graph):
            let cell = cell as! SearchFilterCellPriceRange
            cell.render(filterPriceGraph: graph)

        case .rowTime(let timings):
            let cell = cell as! SearchFilterCellTiming
            cell.render(timings: timings)

        case let .cellTag(tag, count, selected):
            let cell = cell as! SearchFilterCellTag
            cell.render(title: tag, count: count, selected: selected)

        default: return
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch items[indexPath.row] {
        case .cellTag(let tag, _, _):
            guard UserSetting.allow(remove: tag, controller: self) else {
                return
            }
            self.manager.select(tag: tag)

        case .cellTagMore:
            self.manager.select(category: .moreCuisine)

        default: return
        }
    }
}

// MARK: GoTo
extension SearchFilterController {
    enum GoTo {
        case location
    }

    func goTo(_ goTo: GoTo) {
        switch goTo {
        case .location:
            let controller = SearchFilterLocationController(searchQuery: self.manager.searchQuery) { area in
                self.manager.select(area: area, persist: true)
            }
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
}

fileprivate class SearchFilterHeaderView: UIView {
    fileprivate var manager: SearchFilterController!
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
            make.left.equalTo(self).inset(24)
            make.right.equalTo(self)
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
                if text.lowercased() == "nearby" {
                    self.tagCollection.add(type: .filterTag(text))
                } else {
                    self.tagCollection.add(type: .filterTagClose(text))
                }

            case .hour(let text):
                self.tagCollection.add(type: .filterTagClose(text))
            case .tag(let text):
                self.tagCollection.add(type: .filterTagClose(text))
            case .price(let text):
                self.tagCollection.add(type: .filterTagClose(text))
            }
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

fileprivate class SearchFilterBottomView: UIView {
    fileprivate let applyBtn: UIButton = {
        let applyBtn = UIButton()
        applyBtn.layer.cornerRadius = 3
        applyBtn.backgroundColor = .primary
        applyBtn.setTitleColor(.white, for: .normal)
        applyBtn.titleLabel!.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return applyBtn
    }()
    fileprivate let indicator: NVActivityIndicatorView = {
        let indicator = NVActivityIndicatorView(frame: .zero, type: .ballBeat, color: .primary600, padding: 10)
        indicator.stopAnimating()
        return indicator
    }()

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.addSubview(applyBtn)
        self.addSubview(indicator)

        applyBtn.snp.makeConstraints { (make) in
            make.top.equalTo(self).inset(12)
            make.bottom.equalTo(self.safeArea.bottom).inset(12)
            make.right.left.equalTo(self).inset(24)
            make.height.equalTo(46)
        }

        indicator.snp.makeConstraints { make in
            make.edges.equalTo(applyBtn)
        }
    }

    func render(count: Int?) {
        if let count = count {
            Analytics.logEvent("search_filter_count", parameters: [
                "count": count
            ])
            self.indicator.stopAnimating()

            if count == 0 {
                self.applyBtn.setTitle("No Results".localized(), for: .normal)
                self.applyBtn.backgroundColor = .white
                self.applyBtn.setTitleColor(.primary, for: .normal)
            } else {
                self.applyBtn.setTitle(FilterCount.countTitle(count: count), for: .normal)
                self.applyBtn.backgroundColor = .primary
                self.applyBtn.setTitleColor(.white, for: .normal)
            }
        } else {
            self.indicator.startAnimating()
            self.applyBtn.setTitle(nil, for: .normal)
            self.applyBtn.backgroundColor = .white
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

extension FilterCount {
    static func countTitle(count: Int,
                           empty: String = "No Results".localized(),
                           prefix: String = "See".localized(),
                           postfix: String = "Restaurants".localized()) -> String {
        if count == 0 {
            return empty
        } else if count >= 100 {
            return "\(prefix) 100+ \(postfix)"
        } else if count <= 10 {
            return "\(prefix) \(count) \(postfix)"
        } else {
            let rounded = count / 10 * 10
            return "\(prefix) \(rounded)+ \(postfix)"
        }
    }
}