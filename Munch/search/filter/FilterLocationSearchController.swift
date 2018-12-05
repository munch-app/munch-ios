//
// Created by Fuxing Loh on 22/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import Moya
import RxSwift
import RxCocoa

import NVActivityIndicatorView
import Crashlytics

class FilterLocationSearchController: UIViewController {
    private let onDismiss: ((SearchQuery?) -> Void)
    private let searchQuery: SearchQuery

    private let provider = MunchProvider<SearchFilterService>()
    private let disposeBag = DisposeBag()

    private var areas: [Area] = []
    private var items: [(String, [Area])] = []

    fileprivate let headerView = FilterLocationSearchHeaderView()
    fileprivate let indicator: NVActivityIndicatorView = {
        let indicator = NVActivityIndicatorView(frame: .zero, type: .ballTrianglePath, color: .secondary500, padding: 0)
        indicator.startAnimating()
        return indicator
    }()

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50

        tableView.tableFooterView = UIView(frame: .zero)

        tableView.separatorStyle = .none
        return tableView
    }()

    init(searchQuery: SearchQuery, onDismiss: @escaping ((SearchQuery?) -> Void)) {
        self.onDismiss = onDismiss
        self.searchQuery = searchQuery
        super.init(nibName: nil, bundle: nil)

        self.registerCells()
        self.addTargets()
    }

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
        self.view.addSubview(indicator)

        headerView.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.left.right.equalTo(self.view)
        }

        tableView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.headerView.snp.bottom)
            make.bottom.equalTo(self.view)
        }

        indicator.snp.makeConstraints { maker in
            maker.center.equalTo(tableView)
            maker.width.height.equalTo(40)
        }

        self.provider.rx.request(.areas)
                .map { response -> [Area] in
                    return try response.map(data: [Area].self)
                }
                .subscribe { result in
                    switch result {
                    case .success(let areas):
                        self.indicator.isHidden = true
                        self.areas = areas
                        self.items = areas.mapOrdered()
                        self.tableView.reloadData()

                    case .error(let error):
                        self.alert(error: error)
                        Crashlytics.sharedInstance().recordError(error)
                    }
                }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Register Actions
extension FilterLocationSearchController {
    func addTargets() {
        self.headerView.closeButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)

        self.headerView.field.rx.text
                .debounce(0.3, scheduler: MainScheduler.instance)
                .flatMapFirst { s -> Observable<[(String, [Area])]> in
                    guard let text = s?.lowercased(), text.count > 2 else {
                        return Observable.just(self.areas.mapOrdered())
                    }

                    return Observable.just(self.areas.search(text: text).mapOrdered())
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

    @objc func actionCancel(_ sender: Any) {
        self.onDismiss(nil)
        self.dismiss(animated: true)
    }
}

// MARK: TableView Cells
extension FilterLocationSearchController: UITableViewDataSource, UITableViewDelegate {
    func registerCells() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(type: FilterLocationSearchCell.self)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return items[section].0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].1.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(type: FilterLocationSearchCell.self)
        cell.render(with: items[indexPath.section].1[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        var searchQuery = self.searchQuery
        searchQuery.filter.location.type = .Where
        searchQuery.filter.location.areas = [items[indexPath.section].1[indexPath.row]]
        searchQuery.filter.location.points = []

        self.onDismiss(searchQuery)
        self.dismiss(animated: true)
    }
}

class FilterLocationSearchCell: UITableViewCell {
    private let titleLabel = UILabel(style: .regular)
            .with(numberOfLines: 1)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self).inset(8)
            make.left.equalTo(self).inset(24)
            make.right.equalTo(self).inset(24)
        }
    }


    @discardableResult
    func render(with area: Area) -> FilterLocationSearchCell {
        titleLabel.text = area.name
        return self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FilterLocationSearchHeaderView: UIView {
    let field: MunchSearchTextField = {
        let field = MunchSearchTextField()
        field.placeholder = "Search"
        return field
    }()
    let closeButton: UIButton = {
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
        self.addSubview(closeButton)

        field.snp.makeConstraints { maker in
            maker.top.equalTo(self.safeArea.top).inset(12)
            maker.bottom.equalTo(self).inset(12)
            maker.height.equalTo(36)
            maker.left.equalTo(self).inset(24)
            maker.right.equalTo(closeButton.snp.left).inset(-16)
        }

        closeButton.snp.makeConstraints { maker in
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

extension Array where Element == Area {
    fileprivate static let alpha: [String] = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "#"]

    func search(text: String) -> [Area] {
        return self.filter { area in
            area.name.lowercased().contains(text.lowercased())
        }
    }

    func mapOrdered() -> [(String, [Area])] {
        var mapping = [String: [Area]]()
        Array.alpha.forEach { s in
            mapping[s] = []
        }

        self.forEach { (area: Area) in
            guard let first = area.name.lowercased()[0] else {
                return
            }
            let char = String(first)

            if mapping[char] != nil {
                mapping[char]!.append(area)
            } else {
                mapping["#"]!.append(area)
            }
        }

        return Array.alpha.map { s -> (String, [Area]) in
            return (s.uppercased(), mapping[s]!)
        }.filter { (s: String, areas: [Area]) -> Bool in
            return !areas.isEmpty
        }
    }
}