//
// Created by Fuxing Loh on 17/3/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class SearchRootController: UINavigationController, UINavigationControllerDelegate {
    init(searchQuery: SearchQuery, extensionDismiss: @escaping((SearchQuery?) -> Void)) {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [SearchController(searchQuery: searchQuery, extensionDismiss: extensionDismiss)]
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

class SearchController: UIViewController {
    private let onExtensionDismiss: ((SearchQuery?) -> Void)

    fileprivate let headerView = SearchHeaderView()

    fileprivate let tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50

        tableView.tableFooterView = UIView(frame: CGRect.zero)

        tableView.contentInset.top = 8
        tableView.contentInset.bottom = 16
        tableView.separatorStyle = .none
        return tableView
    }()

    private var results: [SearchResultType]?
    private var firstLoad: Bool = true
    private var searchQuery: SearchQuery

    init(searchQuery: SearchQuery, extensionDismiss: @escaping((SearchQuery?) -> Void)) {
        self.onExtensionDismiss = extensionDismiss
        self.searchQuery = searchQuery
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

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.headerView.cancelButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)
        self.headerView.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.headerView.textField.addTarget(self, action: #selector(textFieldShouldReturn(_:)), for: .editingDidEndOnExit)

        self.headerView.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.left.right.equalTo(self.view)
        }

        self.tableView.snp.makeConstraints { make in
            make.top.equalTo(self.headerView.snp.bottom)
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
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
        self.onExtensionDismiss(searchQuery)
        self.dismiss(animated: true)
    }

    @objc func textFieldDidChange(_ sender: Any) {
        self.results = []
        self.tableView.reloadData()

        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.perform(#selector(textFieldDidCommit(textField:)), with: headerView.textField, afterDelay: 0.4)
    }

    @objc func textFieldDidCommit(textField: UITextField) {
        if let text = textField.text, text.count >= 2 {
            // Change to null when get committed
            self.results = nil
            self.tableView.reloadData()

            let latLng = DiscoverFilterControllerManager.getContextLatLng(searchQuery: searchQuery)
            MunchApi.search.search(text: text, latLng: latLng, query: searchQuery) { meta, assumptions, places in
                if meta.isOk() {
                    self.results = SearchController.map(assumptions: assumptions, places: places)
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

    class func map(assumptions: [AssumptionQueryResult], places: [Place]) -> [SearchResultType] {
        var list = [SearchResultType]()

        for assumption in assumptions {
            list.append(.assumption(assumption))
        }

        for place in places {
            list.append(.place(place))
        }

        if list.isEmpty {
            list.append(.empty)
        }

        return list
    }
}

extension SearchController: UITableViewDataSource, UITableViewDelegate {
    func registerCell() {
        tableView.register(SearchCellPlace.self, forCellReuseIdentifier: SearchCellPlace.id)
        tableView.register(SearchCellLoading.self, forCellReuseIdentifier: SearchCellLoading.id)
        tableView.register(SearchCellNoResult.self, forCellReuseIdentifier: SearchCellNoResult.id)
        tableView.register(SearchCellAssumptionQueryResult.self, forCellReuseIdentifier: SearchCellAssumptionQueryResult.id)
    }

    var items: [SearchResultType] {
        if let text = headerView.textField.text {
            if text.isEmpty {
                return []
            } else if text.count < 3 {
                return []
            } else if text.count >= 3 {
                if let results = self.results {
                    return results
                }
                return [SearchResultType.loading]
            }
        }
        return []
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.row] {
        case .place(let place):
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchCellPlace.id) as! SearchCellPlace
            cell.render(place: place)
            return cell

        case .assumption(let queryResult):
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchCellAssumptionQueryResult.id) as! SearchCellAssumptionQueryResult
            cell.render(queryResult: queryResult, controller: self)
            return cell

        case .loading:
            return tableView.dequeueReusableCell(withIdentifier: SearchCellLoading.id) as! SearchCellLoading

        case .empty:
            return tableView.dequeueReusableCell(withIdentifier: SearchCellNoResult.id) as! SearchCellNoResult
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch items[indexPath.row] {
        case .place(let place):
            select(placeId: place.id)
        default: return
        }
    }

    func select(placeId: String?) {
        if let placeId = placeId {
            let placeController = PlaceViewController(placeId: placeId)
            self.navigationController?.pushViewController(placeController, animated: true)
        }
    }

    func select(searchQuery: SearchQuery) {
        self.onExtensionDismiss(searchQuery)
        self.dismiss(animated: true)
    }
}

fileprivate class SearchHeaderView: UIView {
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

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.addSubview(textField)
        self.addSubview(cancelButton)
        self.backgroundColor = .white

        textField.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top).inset(8)
            make.bottom.equalTo(self).inset(10)

            make.left.equalTo(self).inset(24)
            make.right.equalTo(cancelButton.snp.left)
            make.height.equalTo(36)
        }

        cancelButton.snp.makeConstraints { make in
            make.width.equalTo(90)
            make.top.bottom.equalTo(textField)
            make.right.equalTo(self)
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