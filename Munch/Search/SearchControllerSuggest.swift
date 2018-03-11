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

class SearchSuggestRootController: UINavigationController, UINavigationControllerDelegate {
    init(searchQuery: SearchQuery, extensionDismiss: @escaping((SearchQuery?) -> Void)) {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [SearchSuggestController(searchQuery: searchQuery, extensionDismiss: extensionDismiss)]
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

class SearchSuggestController: UIViewController {
    private let onExtensionDismiss: ((SearchQuery?) -> Void)
    let manager: SearchControllerSuggestManager

    fileprivate let headerView = SearchSuggestHeaderView()
    fileprivate let bottomView = SearchSuggestBottomView()
    fileprivate let tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50

        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.contentInset.top = 7
        tableView.contentInset.bottom = 14
        tableView.separatorStyle = .none
        return tableView
    }()
    private var suggests: [SearchSuggestType]?
    private var firstLoad: Bool = true
    private var searchQuery: SearchQuery

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

        if firstLoad {
            self.headerView.textField.becomeFirstResponder()
            self.firstLoad = false
        }
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

        self.bottomView.applyBtn.addTarget(self, action: #selector(actionApply(_:)), for: .touchUpInside)

        self.headerView.tagCollection.render(query: manager.searchQuery)
        self.bottomView.render(searchQuery: manager.searchQuery)
        self.manager.addUpdateHook { query in
            self.headerView.tagCollection.render(query: query)
            self.bottomView.render(searchQuery: query)
            self.tableView.reloadData()

            if self.searchQuery != query {
                self.headerView.textField.text = nil
                self.headerView.textField.resignFirstResponder()
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
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.headerView.textField.resignFirstResponder()
    }

    @objc func actionCancel(_ sender: Any) {
        self.onExtensionDismiss(nil)
        self.dismiss(animated: true)
    }

    @objc func actionApply(_ sender: Any) {
        self.onExtensionDismiss(manager.searchQuery)
        self.dismiss(animated: true)
    }

    @objc func textFieldDidChange(_ sender: Any) {
        // Reset View
        self.suggests = []
        self.tableView.reloadData()

        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.perform(#selector(textFieldDidCommit(textField:)), with: headerView.textField, afterDelay: 1.0)
    }

    @objc func textFieldDidCommit(textField: UITextField) {
        if let text = textField.text, text.count >= 3 {
            // Change to null when get committed
            self.suggests = nil
            self.tableView.reloadData()

            MunchApi.search.suggest(text: text, query: self.manager.searchQuery) { meta, assumptions, places, results, tags in
                if meta.isOk() {
                    self.suggests = SearchControllerSuggestManager.map(assumptions: assumptions, places: places, locationContainers: results, tags: tags)
                    self.tableView.reloadData()
                } else {
                    self.present(meta.createAlert(), animated: true)
                }
            }
        } else {
            self.tableView.reloadData()
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

extension SearchSuggestController: UITableViewDataSource, UITableViewDelegate {
    func registerCell() {
        tableView.register(SearchSuggestCellHeader.self, forCellReuseIdentifier: SearchSuggestCellHeader.id)
        tableView.register(SearchSuggestCellHeaderMore.self, forCellReuseIdentifier: SearchSuggestCellHeaderMore.id)
        tableView.register(SearchSuggestCellLocation.self, forCellReuseIdentifier: SearchSuggestCellLocation.id)
        tableView.register(SearchSuggestCellTag.self, forCellReuseIdentifier: SearchSuggestCellTag.id)
        tableView.register(SearchSuggestCellTiming.self, forCellReuseIdentifier: SearchSuggestCellTiming.id)
        tableView.register(SearchSuggestCellNoResult.self, forCellReuseIdentifier: SearchSuggestCellNoResult.id)
        tableView.register(SearchSuggestCellPlace.self, forCellReuseIdentifier: SearchSuggestCellPlace.id)
        tableView.register(SearchSuggestCellAssumption.self, forCellReuseIdentifier: SearchSuggestCellAssumption.id)
        tableView.register(SearchSuggestCellLoading.self, forCellReuseIdentifier: SearchSuggestCellLoading.id)
        tableView.register(SearchSuggestCellPriceRange.self, forCellReuseIdentifier: SearchSuggestCellPriceRange.id)
    }

    var items: [SearchSuggestType] {
        if let text = headerView.textField.text {
            if text.isEmpty {
                return self.manager.suggestions
            } else if text.count < 3 {
                return []
            } else if text.count >= 3 {
                if let suggests = self.suggests {
                    return suggests
                }
                return [SearchSuggestType.loading]
            }
        }
        return []
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.row] {
        case .empty:
            return tableView.dequeueReusableCell(withIdentifier: SearchSuggestCellNoResult.id) as! SearchSuggestCellNoResult

        case .loading:
            return tableView.dequeueReusableCell(withIdentifier: SearchSuggestCellLoading.id) as! SearchSuggestCellLoading

        case .assumption(let query):
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchSuggestCellAssumption.id) as! SearchSuggestCellAssumption
            cell.render(query: query)
            return cell

        case .header(let title):
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchSuggestCellHeader.id) as! SearchSuggestCellHeader
            cell.render(title: title)
            return cell

        case .headerMore(let title):
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchSuggestCellHeaderMore.id) as! SearchSuggestCellHeaderMore
            cell.render(title: title)
            return cell

        case .location(let locations):
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchSuggestCellLocation.id) as! SearchSuggestCellLocation
            cell.render(locations: locations, controller: self)
            return cell

        case .priceRange:
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchSuggestCellPriceRange.id) as! SearchSuggestCellPriceRange
            cell.controller = self
            return cell

        case .tag(let tag):
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchSuggestCellTag.id) as! SearchSuggestCellTag
            let text = tag.name ?? ""
            cell.render(title: text, selected: manager.isSelected(tag: text))
            return cell

        case .time(let timings):
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchSuggestCellTiming.id) as! SearchSuggestCellTiming
            cell.render(timings: timings, controller: self)
            return cell

        case .place(let place):
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchSuggestCellPlace.id) as! SearchSuggestCellPlace
            cell.render(place: place)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch items[indexPath.row] {
        case .tag(let tag):
            let text = tag.name ?? ""
            manager.select(tag: text, selected: !manager.isSelected(tag: text))

        case .assumption(let query):
            Analytics.logEvent(AnalyticsEventSearch, parameters: [
                AnalyticsParameterSearchTerm: query.text as NSObject,
                "result_count": query.resultCount as NSObject
            ])
            self.onExtensionDismiss(query.searchQuery)
            self.dismiss(animated: true)

        case .headerMore(let title):
            let controller = SearchSuggestTagController(searchQuery: manager.searchQuery, type: title) { query in
                if let query = query {
                    self.manager.setSearchQuery(searchQuery: query)
                }
            }
            self.navigationController?.pushViewController(controller, animated: true)

        case .place(let place):
            if let placeId = place.id {
                let placeController = PlaceViewController(placeId: placeId)
                self.navigationController?.pushViewController(placeController, animated: true)
            }

        default: return
        }
    }
}

fileprivate class SearchSuggestHeaderView: UIView, SearchFilterTagDelegate {
    fileprivate var controller: SearchSuggestController!
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

        textField.placeholder = "Search Anything"
        textField.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
        return textField
    }()
    fileprivate let cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.titleEdgeInsets.right = 24
        button.contentHorizontalAlignment = .right
        return button
    }()
    fileprivate let tagCollection = SearchFilterTagCollection()

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.addSubview(textField)
        self.addSubview(cancelButton)
        self.addSubview(tagCollection)
        self.tagCollection.delegate = self

        self.backgroundColor = .white

        textField.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top).inset(8)
            make.left.equalTo(self).inset(24)
            make.right.equalTo(cancelButton.snp.left)
            make.height.equalTo(36)
        }

        cancelButton.snp.makeConstraints { make in
            make.width.equalTo(90)
            make.top.equalTo(self.safeArea.top).inset(8)
            make.right.equalTo(self)
            make.height.equalTo(36)
        }

        tagCollection.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.equalTo(textField.snp.bottom).inset(-9)
            make.bottom.equalTo(self).inset(8)
            make.height.equalTo(34)
        }
    }

    func tagCollection(selectedLocation name: String, for tagCollection: SearchFilterTagCollection) {
    }

    func tagCollection(selectedHour name: String, for tagCollection: SearchFilterTagCollection) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { action in
            self.controller.manager.select(hour: name)
        })
        addAlert(removeAll: alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.controller.present(alert, animated: true)
    }

    func tagCollection(selectedPrice name: String, for tagCollection: SearchFilterTagCollection) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { action in
            self.controller.manager.resetPrice()
        })
        addAlert(removeAll: alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.controller.present(alert, animated: true)
    }

    func tagCollection(selectedTag name: String, for tagCollection: SearchFilterTagCollection) {
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
        self.shadow(vertical: 1.5)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchSuggestBottomView: UIView {
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
        MunchApi.search.count(query: searchQuery, callback: { (meta, count) in
            if let count = count {
                self.applyBtn.setTitle(SearchSuggestBottomView.countTitle(count: count), for: .normal)
            }
        })
    }

    class func countTitle(count: Int) -> String {
        if count == 0 {
            return "No Results"
        } else if count > 100 {
            return "See 100+ Restaurants"
        } else if count <= 10 {
            return "See \(count) Restaurants"
        } else {
            let rounded = count / 10 * 10
            return "See \(rounded)+ Restaurants"
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: -1.5)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}