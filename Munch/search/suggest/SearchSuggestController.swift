//
// Created by Fuxing Loh on 21/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import Moya
import RxSwift
import RxCocoa

import FirebaseAnalytics

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
    private var searchQuery: SearchQuery

    private let provider = MunchProvider<SearchService>()
    private let disposeBag = DisposeBag()

    fileprivate let headerView = SearchSuggestHeaderView()

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

    fileprivate var cellRecent: SearchSuggestCellRecentPlace!
    fileprivate var cellAssumption: SearchSuggestCellAssumptionResult!
    fileprivate var cellTextSuggest: SearchSuggestCellTextSuggest!

    private var items: [SearchSuggestType] = [.rowRecent]
    private var firstLoad: Bool = true

    init(searchQuery: SearchQuery, extensionDismiss: @escaping((SearchQuery?) -> Void)) {
        self.onExtensionDismiss = extensionDismiss
        self.searchQuery = searchQuery
        super.init(nibName: nil, bundle: nil)

        self.registerCells()
        self.registerActions()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(tableView)
        self.view.addSubview(headerView)

        self.tableView.delegate = self
        self.tableView.dataSource = self

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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchSuggestController: UITableViewDataSource, UITableViewDelegate {
    func registerCells() {
        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.cellRecent = SearchSuggestCellRecentPlace(controller: self)
        self.cellAssumption = SearchSuggestCellAssumptionResult(controller: self)
        self.cellTextSuggest = SearchSuggestCellTextSuggest(controller: self)

        func register(cellClass: UITableViewCell.Type) {
            tableView.register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
        }

        register(cellClass: SearchSuggestCellHeaderRestaurant.self)
        register(cellClass: SearchSuggestCellLoading.self)
        register(cellClass: SearchSuggestCellPlace.self)
        register(cellClass: SearchSuggestCellNoResult.self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.row] {
        case .place:
            return tableView.dequeueReusableCell(withIdentifier: String(describing: SearchSuggestCellPlace.self)) as! SearchSuggestCellPlace

        case .rowSuggest: return cellTextSuggest
        case .rowAssumption: return cellAssumption
        case .rowRecent: return cellRecent

        case .headerRestaurant:
            return tableView.dequeueReusableCell(withIdentifier: String(describing: SearchSuggestCellHeaderRestaurant.self)) as! SearchSuggestCellHeaderRestaurant

        case .loading:
            return tableView.dequeueReusableCell(withIdentifier: String(describing: SearchSuggestCellLoading.self)) as! SearchSuggestCellLoading

        case .empty:
            return tableView.dequeueReusableCell(withIdentifier: String(describing: SearchSuggestCellNoResult.self)) as! SearchSuggestCellNoResult
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch items[indexPath.row] {
        case .place(let place):
            Analytics.logEvent(AnalyticsEventViewItem, parameters: [
                AnalyticsParameterItemID: "place-\(place.placeId)" as NSObject,
                AnalyticsParameterItemCategory: "search_place" as NSObject
            ])

            let cell = cell as! SearchSuggestCellPlace
            cell.render(place: place)

        case .rowSuggest(let suggests):
            let cell = cell as! SearchSuggestCellTextSuggest
            cell.render(texts: suggests)

        case .rowAssumption(let queryResult):
            let cell = cell as! SearchSuggestCellAssumptionResult
            cell.render(result: queryResult)

        case .rowRecent:
            let cell = cell as! SearchSuggestCellRecentPlace
            cell.render()

        default: return
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch items[indexPath.row] {
        case .place(let place):
            Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                AnalyticsParameterItemID: "place-\(place.placeId)" as NSObject,
                AnalyticsParameterContentType: "search_place" as NSObject
            ])
            apply(.place(place))
        default: return
        }
    }
}

// MARK: ACTIONABLE
extension SearchSuggestController {
    private func registerActions() {
        self.headerView.cancelButton.addTarget(self, action: #selector(action(cancel:)), for: .touchUpInside)

        let textControl: ControlProperty<String?> = self.headerView.textField.rx.text
        textControl
                .debounce(0.3, scheduler: MainScheduler.instance)
                .distinctUntilChanged()
                .flatMapFirst { s -> Observable<[SearchSuggestType]> in
                    guard let text = s?.lowercased(), text.count > 2 else {
                        return Observable.just([.rowRecent])
                    }

                    self.items = [.loading]
                    self.tableView.reloadData()

                    return self.provider.rx.request(.suggest(text, self.searchQuery))
                            .map { response throws -> SuggestData in
                                try response.map(data: SuggestData.self)
                            }
                            .map { data -> [SearchSuggestType] in
                                return data.items
                            }
                            .asObservable()
                }
                .catchError { (error: Error) in
                    self.alert(error: error)
                    return Observable.empty()
                }
                .subscribe { event in
                    switch event {
                    case .next(let items):
                        self.items = items
                        self.tableView.reloadData()
                    case .error(let error):
                        self.alert(error: error)
                    case .completed: return
                    }
                }
                .disposed(by: disposeBag)
    }

    enum Actionable {
        case text(String)
        case search(SearchQuery)
        case place(Place)
        case cancel
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.headerView.textField.resignFirstResponder()
    }

    @objc func action(cancel: Any) {
        self.apply(.cancel)
    }

    func apply(_ goTo: Actionable) {
        switch goTo {
        case .place(let place):
            let controller = PlaceController(place: place)
            self.navigationController?.pushViewController(controller, animated: true)

        case .text(let text):
            self.headerView.textField.text = text
            self.headerView.textField.sendActions(for: .valueChanged)

        case .search(let searchQuery):
            self.onExtensionDismiss(searchQuery)
            self.dismiss(animated: true)

        case .cancel:
            self.dismiss(animated: true)
        }
    }
}

fileprivate class SearchSuggestHeaderView: UIView {
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

        textField.placeholder = "Search e.g. Italian in Marina Bay".localized()
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