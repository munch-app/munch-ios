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
                self.headerView.textField.text = nil
                self.headerView.textField.resignFirstResponder()
                self.tableView.reloadData()
            case .loading:
                self.results = nil
                self.tableView.reloadData()
            case .result:
                self.tableView.reloadData()
            case .search:
                self.headerView.textField.text = nil
                self.tableView.reloadData()
            case .empty:
                self.results = []
                self.tableView.reloadData()
            }
        }
    }

    enum State {
        case filter
        case search
        case result
        case loading
        case empty
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
        self.headerView.textField.resignFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(tableView)
        self.view.addSubview(headerView)
        self.view.addSubview(bottomView)

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.headerView.controller = self

        self.headerView.cancelButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)
        self.headerView.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.headerView.textField.addTarget(self, action: #selector(textFieldShouldReturn(_:)), for: .editingDidEndOnExit)
        self.headerView.textField.addTarget(self, action: #selector(textFieldDidBegin(_:)), for: .editingDidBegin)

        self.bottomView.applyBtn.addTarget(self, action: #selector(actionApply(_:)), for: .touchUpInside)

        self.headerView.tagCollection.render(query: manager.searchQuery)
        self.bottomView.render(searchQuery: manager.searchQuery)

        self.manager.addUpdateHook { query in
            self.headerView.tagCollection.render(query: query)
            self.bottomView.render(searchQuery: query)

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
            make.top.equalTo(self.view)
            make.bottom.equalTo(self.bottomView.snp.top)
        }

        self.tableView.layoutIfNeeded()
        self.tableView.contentInset.top = self.headerView.contentHeight
        self.tableView.contentOffset.y = -62
        self.headerView.topConstraint.update(inset: 36)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.headerView.textField.resignFirstResponder()
        if self.state == State.search {
            self.state = .filter
        }
    }

    @objc func actionCancel(_ sender: Any) {
        self.onExtensionDismiss(nil)
        self.dismiss(animated: true)
    }

    @objc func actionApply(_ sender: Any) {
        self.onExtensionDismiss(manager.searchQuery)
        self.dismiss(animated: true)
    }

    @objc func textFieldDidBegin(_ sender: Any) {
        self.state = .search
    }

    @objc func textFieldDidChange(_ sender: Any) {
        self.state = .empty
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.perform(#selector(textFieldDidCommit(textField:)), with: headerView.textField, afterDelay: 0.4)
    }

    @objc func textFieldDidCommit(textField: UITextField) {
        if let text = textField.text, text.count >= 2 {
            self.state = .loading

            MunchApi.discover.filterSuggest(text: text, latLng: self.manager.getContextLatLng(), query: self.manager.searchQuery) { meta, locations, tags in
                if meta.isOk() {
                    self.results = DiscoverFilterControllerManager.map(locations: locations, tags: tags)
                    self.state = .result
                } else {
                    self.present(meta.createAlert(), animated: true)
                }
            }
        } else {
            self.state = .empty
        }
    }

    @objc func textFieldShouldReturn(_ sender: Any) -> Bool {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        textFieldDidCommit(textField: headerView.textField)
        return true
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
        case .search:
            return [DiscoverFilterType.description]
        case .empty:
            return []
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
            self.headerView.textField.becomeFirstResponder()
            self.state = .search

        case .tagMore(let title):
            let controller = SearchSuggestTagController(searchQuery: manager.searchQuery, type: title) { query in
                if let query = query {
                    self.manager.setSearchQuery(searchQuery: query)
                }
            }
            self.navigationController?.pushViewController(controller, animated: true)
        default: return
        }
    }
}

fileprivate class DiscoverFilterHeaderView: UIView, FilterTagViewDelegate {
    fileprivate var controller: DiscoverFilterController!
    fileprivate let textField: SearchTextField = {
        let textField = SearchTextField()
        textField.clearButtonMode = .whileEditing
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .search

        textField.layer.cornerRadius = 4
        textField.color = UIColor(hex: "2E2E2E")
        textField.backgroundColor = UIColor.init(hex: "EBEBEB")

        textField.leftImage = UIImage(named: "SC-Search-18")
        textField.leftImagePadding = 3
        textField.leftImageWidth = 32
        textField.leftImageSize = 18

        textField.placeholder = "Search Location or Filter"
        textField.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
        return textField
    }()
    fileprivate let cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("CANCEL", for: .normal)
        button.setTitleColor(UIColor(hex: "333333"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        button.titleEdgeInsets.right = 24
        button.contentHorizontalAlignment = .right
        button.backgroundColor = .white
        return button
    }()
    fileprivate let tagCollection: FilterTagView = {
        let config = FilterTagView.DefaultTagConfig()
        config.tagExtraSpace = CGSize(width: 21, height: 16)
        let view = FilterTagView(tagConfig: config)
        view.backgroundColor = .white
        return view
    }()
    var topConstraint: Constraint! = nil

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.backgroundColor = .white

        self.addSubview(textField)
        self.addSubview(cancelButton)
        self.addSubview(tagCollection)

        self.tagCollection.delegate = self

        cancelButton.snp.makeConstraints { make in
            make.width.equalTo(84)
            make.right.equalTo(self)

            make.top.bottom.equalTo(self.tagCollection)
        }

        tagCollection.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.right.equalTo(cancelButton.snp.left)
            make.top.equalTo(self.safeArea.top).inset(8)

            make.height.equalTo(37)
        }

        textField.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.height.equalTo(36)


            self.topConstraint = make.top.equalTo(tagCollection.snp.bottom).constraint
            self.topConstraint.update(inset: 36)

            make.bottom.equalTo(self).inset(10)
        }
    }

    func tagCollection(selectedLocation name: String, for tagCollection: FilterTagView) {
        if name.lowercased() == "nearby" {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { action in
                self.controller.manager.select(location: nil)
            })
            addAlert(removeAll: alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.controller.present(alert, animated: true)
        }
    }

    func tagCollection(selectedHour name: String, for tagCollection: FilterTagView) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { action in
            self.controller.manager.select(hour: name)
        })
        addAlert(removeAll: alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.controller.present(alert, animated: true)
    }

    func tagCollection(selectedPrice name: String, for tagCollection: FilterTagView) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { action in
            self.controller.manager.resetPrice()
        })
        addAlert(removeAll: alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.controller.present(alert, animated: true)
    }

    func tagCollection(selectedTag name: String, for tagCollection: FilterTagView) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { action in
            self.controller.manager.reset(tags: [name])
        })
        addAlert(removeAll: alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.controller.present(alert, animated: true)
    }

    func addAlert(removeAll alert: UIAlertController) {
        alert.addAction(UIAlertAction(title: "Remove All", style: .destructive) { action in
            self.controller.manager.reset()
        })
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: 2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let contentHeight: CGFloat = 99 + 7
    let extendedHeight: CGFloat = 44
}

// Header Scroll to Hide Functions
extension DiscoverFilterHeaderView {
    var maxHeight: CGFloat {
        // contentHeight + safeArea.top
        return self.safeAreaInsets.top + contentHeight
    }

    func contentDidScroll(scrollView: UIScrollView) {
        let height = calculateHeight(scrollView: scrollView)
        let inset = extendedHeight - height - 8
        self.topConstraint.update(inset: inset)
    }

    /**
     nil means don't move
     */
    func contentShouldMove(scrollView: UIScrollView) -> CGFloat? {
        let height = calculateHeight(scrollView: scrollView)

        // Already fully closed or opened
        if (height == extendedHeight || height == 0.0) {
            return nil
        }


        if (height < extendedHeight / 2) {
            // To close
            return -maxHeight + extendedHeight
        } else {
            // To open
            return -maxHeight
        }
    }

    private func calculateHeight(scrollView: UIScrollView) -> CGFloat {
        let y = scrollView.contentOffset.y
        if y <= -maxHeight {
            return extendedHeight
        } else if y >= -maxHeight + extendedHeight {
            return 0
        } else {
            return extendedHeight - (maxHeight + y)
        }
    }
}

// MARK: Scroll View
extension DiscoverFilterController {
    func scrollsToTop(animated: Bool = true) {
        tableView.contentOffset.y = -self.headerView.contentHeight
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.headerView.contentDidScroll(scrollView: scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (!decelerate) {
            scrollViewDidFinish(scrollView)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidFinish(scrollView)
    }

    func scrollViewDidFinish(_ scrollView: UIScrollView) {
        // Check nearest locate and move to it
        if let y = self.headerView.contentShouldMove(scrollView: scrollView) {
            let point = CGPoint(x: 0, y: y)
            scrollView.setContentOffset(point, animated: true)
        }
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
    fileprivate var searchQuery: SearchQuery!

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

    func render(searchQuery: SearchQuery) {
        applyBtn.setTitle("Loading...", for: .normal)
        self.searchQuery = searchQuery
        self.perform(#selector(renderDidCommit(_:)), with: nil, afterDelay: 1.0)
    }

    @objc fileprivate func renderDidCommit(_ sender: Any) {
        MunchApi.discover.filterCount(query: searchQuery, callback: { (meta, count) in
            if let count = count {
                self.applyBtn.setTitle(DiscoverFilterBottomView.countTitle(count: count), for: .normal)
            }
        })
    }

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