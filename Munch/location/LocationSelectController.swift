//
// Created by Fuxing Loh on 2019-02-14.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import Toast_Swift

import Moya
import RxSwift
import RxCocoa

typealias LocationClosure = (NamedLocation?) -> Void

class SearchLocationRootController: MHNavigationController {

    init(onDismiss: @escaping LocationClosure) {
        super.init(controller: SearchLocationController(onDismiss: onDismiss))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchLocationController: MHViewController {
    private let onDismiss: LocationClosure
    private let headerView = HeaderView()

    private let disposeBag = DisposeBag()
    private let locationService = MunchProvider<LocationSearchService>()
    private let userService = MunchProvider<UserLocationService>()

    private let manager = SearchLocationManager()
    private var items = [SearchLocationItem]()

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.contentInset.top = 8
        tableView.contentInset.bottom = 8
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50

        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.separatorInset.left = 24
        return tableView
    }()

    init(onDismiss: @escaping LocationClosure) {
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(tableView)
        self.view.addSubview(headerView)

        headerView.closeBtn.onTouchUpInside { control in
            self.dismiss(animated: true)
        }
        headerView.field.rx.text
                .debounce(0.3, scheduler: MainScheduler.instance)
                .distinctUntilChanged()
                .subscribe { event in
                    switch event {
                    case let .next(text):
                        self.manager.update(text: text ?? "")
                    case let .error(error):
                        self.alert(error: error)

                    case .completed:
                        return
                    }
                }.disposed(by: disposeBag)
        headerView.snp.makeConstraints { maker in
            maker.left.right.top.equalTo(self.view)
        }

        tableView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.headerView.snp.bottom)
            make.bottom.equalTo(self.view)
        }

        self.registerTable()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MunchAnalytic.setScreen("/search/locations")
        self.manager.refresh()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchLocationController: UITableViewDataSource, UITableViewDelegate {
    func registerTable() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(type: SearchLocationIconTextCell.self)
        tableView.register(type: SearchLocationTextCell.self)
        tableView.register(type: SearchLocationHeaderCell.self)
        tableView.register(type: SearchLocationLoadingCell.self)

        self.manager.observe().subscribe { event in
            switch event {
            case .completed:
                return
            case let .error(error):
                self.alert(error: error)
            case let .next(items):
                self.items = items
                self.tableView.reloadData()
            }
        }.disposed(by: disposeBag)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.items[indexPath.row] {
        case .current:
            return tableView.dequeue(type: SearchLocationIconTextCell.self)
                    .render(with: (text: "Current Location", icon: .current))
                    .render(right: nil)

        case let .header(title):
            return tableView.dequeue(type: SearchLocationHeaderCell.self)
                    .render(with: title)

        case let .home(location):
            return tableView.dequeue(type: SearchLocationIconTextCell.self)
                    .render(with: (text: location.name, icon: .home))
                    .render(right: UIImage(named: "Location_Cancel")) {
                        self.removeDialog(location: location)
                    }

        case let .work(location):
            return tableView.dequeue(type: SearchLocationIconTextCell.self)
                    .render(with: (text: location.name, icon: .work))
                    .render(right: UIImage(named: "Location_Cancel")) {
                        self.removeDialog(location: location)
                    }
        case let .saved(location):
            return tableView.dequeue(type: SearchLocationIconTextCell.self)
                    .render(with: (text: location.name, icon: .saved))
                    .render(right: UIImage(named: "Location_Cancel")) {
                        self.removeDialog(location: location)
                    }

        case let .recent(location):
            return tableView.dequeue(type: SearchLocationIconTextCell.self)
                    .render(with: (text: location.name, icon: .recent))
                    .render(right: UIImage(named: "Location_Bookmark")) {
                        let location = UserLocation.new(type: .saved, input: .history, name: location.name, latLng: location.latLng)

                        let controller = LocationSelectSaveController(userLocation: location)
                        self.navigationController?.pushViewController(controller, animated: true)
                    }

        case let .search(named):
            return tableView.dequeue(type: SearchLocationTextCell.self)
                    .render(with: named.name)

        case .loading:
            return tableView.dequeue(type: SearchLocationLoadingCell.self)
        }
    }

    func removeDialog(location: UserLocation) {
        let alert = UIAlertController(title: "Removed Saved Location",
                message: "\(location.name) will be permanently removed from your saved locations. Do you want to continue?",
                preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirm", style: .default) { action in
            self.view.makeToastActivity(.center)
            self.userService.rx.request(.delete(location.sortId))
                    .subscribe { event in
                        self.view.hideToastActivity()
                        switch event {
                        case let .error(error):
                            self.alert(error: error)

                        case .success:
                            self.manager.refresh()
                        }
                    }.disposed(by: self.disposeBag)
            self.manager.refresh()
        })
        self.present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch items[indexPath.row] {
        case .loading: break
        case .header: break
        case .current:
            self.view.makeToastActivity(.center)

            MunchLocation.request(force: true).flatMap { latLng -> Single<NamedLocation> in
                        guard let latLng = latLng else {
                            let error = NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Location not found."])
                            return .error(error)
                        }

                        return self.locationService.rx.request(.current(latLng))
                                .map { response -> NamedLocation in
                                    return try response.map(data: NamedLocation.self)
                                }
                    }
                    .subscribe { event in
                        self.view.hideToastActivity()

                        switch event {
                        case let .error(error):
                            if let error = error as? MoyaError, case let .statusCode(res) = error, res.statusCode == 404 {
                                if res.statusCode == 404, let latLng = MunchLocation.lastLatLng {
                                    self.pop(location: UserLocation.new(
                                            type: .recent,
                                            input: .current,
                                            name: "Current Location",
                                            latLng: latLng
                                    ), saved: true)
                                    return
                                }
                            }

                            self.alert(error: error)
                        case let .success(namedLocation):
                            self.pop(location: UserLocation.new(
                                    type: .recent,
                                    input: .current,
                                    name: namedLocation.name,
                                    latLng: namedLocation.latLng
                            ), saved: true)
                        }
                    }.disposed(by: self.disposeBag)

        case let .recent(location):
            self.pop(location: location, saved: true)
        case let .home(location):
            self.pop(location: location, saved: true)
        case let .work(location):
            self.pop(location: location, saved: true)
        case let .saved(location):
            self.pop(location: location, saved: true)

        case let .search(named):
            self.pop(location: UserLocation.new(
                    type: .recent,
                    input: .searched,
                    name: named.name,
                    latLng: named.latLng
            ), saved: true)
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.headerView.field.resignFirstResponder()
    }

    func pop(location: UserLocation, saved: Bool) {
        if saved, Authentication.isAuthenticated() {
            self.userService.rx.request(.post(location))
                    .subscribe { response in
                        switch response {
                        case .success: return
                        case let .error(error):
                            MunchCrash.record(error: error)
                        }
                    }.disposed(by: disposeBag)
        }

        self.onDismiss(NamedLocation(name: location.name, latLng: location.latLng))
        self.dismiss(animated: true)
    }
}

extension SearchLocationController {
    class HeaderView: UIView {
        let field: MunchSearchTextField = {
            let field = MunchSearchTextField()
            field.placeholder = "Search here"
            return field
        }()
        let closeBtn: UIButton = {
            let button = UIButton()
            button.setImage(UIImage(named: "Search-Header-Close"), for: .normal)
            button.tintColor = .black
            button.imageEdgeInsets.right = 24
            button.contentHorizontalAlignment = .right
            return button
        }()

        override init(frame: CGRect = .zero) {
            super.init(frame: frame)
            self.backgroundColor = .white

            self.addSubview(field)
            self.addSubview(closeBtn)

            field.snp.makeConstraints { maker in
                maker.top.equalTo(self.safeArea.top).inset(12)
                maker.bottom.equalTo(self).inset(12)
                maker.height.equalTo(36)
                maker.left.equalTo(self).inset(24)
                maker.right.equalTo(closeBtn.snp.left).inset(-16)
            }

            closeBtn.snp.makeConstraints { maker in
                maker.top.bottom.equalTo(field)

                maker.right.equalTo(self)
                maker.width.equalTo(24 + 24)
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
}

fileprivate enum SearchLocationItem {
    case header(String)

    case loading
    case current

    case home(UserLocation)
    case work(UserLocation)
    case saved(UserLocation)
    case recent(UserLocation)

    case search(NamedLocation)
}

fileprivate class SearchLocationManager {
    private let userService = MunchProvider<UserLocationService>()
    private let searchService = MunchProvider<LocationSearchService>()

    var text: String = ""
    var userLocation: [UserLocation]?
    var namedLocation: [NamedLocation]?

    private(set) var result: FilterResult?
    private(set) var loading = true

    private var observer: AnyObserver<[SearchLocationItem]>?
    private let disposeBag = DisposeBag()


    func observe() -> Observable<[SearchLocationItem]> {
        return Observable.create { (observer: AnyObserver<[SearchLocationItem]>) in
            self.observer = observer
            self.dispatch()
            // Refresh is send from controller
//            self.refresh()
            return Disposables.create()
        }
    }

    func update(text: String) {
        self.text = text
        self.namedLocation = nil

        self.dispatch()
        guard text.count > 1 else {
            return
        }

        self.searchService.rx.request(.search(text))
                .map { response -> [NamedLocation] in
                    return try response.map(data: [NamedLocation].self)
                }
                .subscribe { event in
                    switch event {
                    case .success(let result):
                        self.namedLocation = result
                        self.dispatch()

                    case .error(let error):
                        self.observer?.on(.error(error))
                    }
                }
                .disposed(by: disposeBag)
    }

    func refresh() {
        guard Authentication.isAuthenticated() else {
            self.userLocation = []
            self.dispatch()
            return
        }

        userService.rx.request(.list(nil, 40))
                .map { response -> [UserLocation] in
                    return try response.map(data: [UserLocation].self)
                }
                .subscribe { event in
                    switch event {
                    case .success(let result):
                        self.userLocation = result
                        self.dispatch()

                    case .error(let error):
                        self.observer?.on(.error(error))
                    }
                }
                .disposed(by: disposeBag)
    }

    func dispatch() {
        self.observer?.on(.next(collect()))
    }

    func collect() -> [SearchLocationItem] {
        if (text.count > 1) {
            guard let locations = self.namedLocation else {
                return [.loading]
            }

            return locations.map { location -> SearchLocationItem in
                return .search(location)
            }
        } else if (text.count > 0) {
            return []
        } else {
            guard let locations = self.userLocation else {
                return [.loading]
            }

            var latLngs = Set<String>()
            var saved = [SearchLocationItem]()
            var recent = [SearchLocationItem]()

            var items = [SearchLocationItem]()
            items.append(.current)

            locations.forEach { location in
                if (latLngs.contains(location.latLng)) {
                    return
                }

                switch (location.type) {
                case .home:
                    saved.append(.home(location))
                case .work:
                    saved.append(.work(location))
                case .saved:
                    saved.append(.saved(location))
                case .recent:
                    recent.append(.recent(location))
                case .other:
                    break
                }

                latLngs.insert(location.latLng)
            }

            if !saved.isEmpty {
                items.append(.header("Saved Locations"))
                items.append(contentsOf: saved)
            }

            if !recent.isEmpty {
                items.append(.header("Recent Searches"))
                items.append(contentsOf: recent)
            }

            return items
        }
    }
}