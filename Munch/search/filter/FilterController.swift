//
// Created by Fuxing Loh on 21/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import RxSwift
import Firebase

import NVActivityIndicatorView

class FilterRootController: UINavigationController, UINavigationControllerDelegate {
    init(searchQuery: SearchQuery, onDismiss: @escaping ((SearchQuery?) -> Void)) {
        super.init(nibName: nil, bundle: nil)
        let controller = FilterController(searchQuery: searchQuery, onDismiss: onDismiss)
        self.viewControllers = [controller]
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

class FilterController: UIViewController {
    private let onDismiss: ((SearchQuery?) -> Void)
    private let manager: FilterManager
    private let disposeBag = DisposeBag()

    private var items: [FilterItem] = []

    fileprivate let headerView = FilterHeaderView()
    fileprivate let bottomView = FilterBottomView()
    fileprivate let indicator: NVActivityIndicatorView = {
        let indicator = NVActivityIndicatorView(frame: .zero, type: .ballTrianglePath, color: .secondary500, padding: 0)
        indicator.startAnimating()
        return indicator
    }()

    fileprivate var cellLocation: FilterItemCellLocation!
    fileprivate var cellPrice: FilterItemCellPrice!
    fileprivate var cellTiming: FilterItemCellTiming!

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50

        tableView.tableFooterView = UIView(frame: .zero)

        tableView.contentInset.top = 16
        tableView.contentInset.bottom = 16
        tableView.separatorStyle = .none
        return tableView
    }()

    init(searchQuery: SearchQuery, onDismiss: @escaping ((SearchQuery?) -> Void)) {
        self.onDismiss = onDismiss
        self.manager = FilterManager(searchQuery: searchQuery)
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
        self.view.addSubview(bottomView)
        self.view.addSubview(indicator)

        self.headerView.manager = self.manager
        self.headerView.searchQuery = self.manager.searchQuery
        self.bottomView.count = nil

        headerView.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.left.right.equalTo(self.view)
        }

        bottomView.snp.makeConstraints { make in
            make.bottom.equalTo(self.view)
            make.left.right.equalTo(self.view)
        }

        tableView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.headerView.snp.bottom)
            make.bottom.equalTo(self.bottomView.snp.top)
        }

        indicator.snp.makeConstraints { maker in
            maker.center.equalTo(tableView)
            maker.width.height.equalTo(40)
        }

        self.manager.observe()
                .catchError { (error: Error) in
                    self.alert(error: error)
                    return Observable.empty()
                }
                .subscribe { event in
                    switch event {
                    case .next(let items):
                        self.headerView.searchQuery = self.manager.searchQuery
                        self.items = items
                        self.tableView.reloadData()

                        // Loading
                        if items.isEmpty {
                            self.bottomView.count = nil
                            self.indicator.isHidden = false
                        } else {
                            self.bottomView.count = self.manager.result?.count
                            self.indicator.isHidden = true
                        }
                    case .error(let error):
                        self.alert(error: error)

                    case .completed:
                        return
                    }
                }.disposed(by: disposeBag)
        self.manager.dispatch(delay: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Register Actions
extension FilterController {
    func addTargets() {
        self.headerView.closeButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)
        self.headerView.resetButton.addTarget(self, action: #selector(actionReset(_:)), for: .touchUpInside)
        self.bottomView.applyButton.addTarget(self, action: #selector(actionApply(_:)), for: .touchUpInside)

        self.headerView.tagView.first.addTarget(self, action: #selector(actionReset(_:)), for: .touchUpInside)
        self.headerView.tagView.second.addTarget(self, action: #selector(actionReset(_:)), for: .touchUpInside)
        self.headerView.tagView.third.addTarget(self, action: #selector(actionReset(_:)), for: .touchUpInside)
    }

    @objc func actionCancel(_ sender: Any) {
        self.onDismiss(nil)
        self.dismiss(animated: true)
    }

    @objc func actionApply(_ sender: Any) {
        self.onDismiss(manager.searchQuery)
        self.dismiss(animated: true)
    }

    @objc func actionReset(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Remove All".localized(), style: .destructive) { action in
            self.manager.reset()
        })
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
        self.present(alert, animated: true)
    }
}

// MARK: TableView Cells
extension FilterController: UITableViewDataSource, UITableViewDelegate {
    func registerCells() {
        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.cellPrice = FilterItemCellPrice(manager: self.manager)
        self.cellLocation = FilterItemCellLocation(manager: self.manager, controller: self)
        self.cellTiming = FilterItemCellTiming(manager: self.manager)

        tableView.register(type: FilterItemCellTagHeader.self)
        tableView.register(type: FilterItemCellTag.self)
        tableView.register(type: FilterItemCellTagMore.self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.row] {
        case .rowLocation:
            cellLocation.reloadData()
            return cellLocation

        case .rowPrice:
            cellPrice.reloadData()
            return cellPrice

        case .rowTiming:
            cellTiming.reloadData()
            return cellTiming

        case let .tagHeader(type):
            let cell = tableView.dequeue(type: FilterItemCellTagHeader.self)
            cell.type = type
            return cell

        case let .tag(count, tag):
            let cell = tableView.dequeue(type: FilterItemCellTag.self)
            let selected = self.manager.searchQuery.filter.tags.contains(where: { $0.tagId == tag.tagId })
            cell.render(name: tag.name, count: count, selected: selected)
            return cell

        case let .tagMore(item):
            let cell = tableView.dequeue(type: FilterItemCellTagMore.self)
            cell.render(with: item)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch items[indexPath.row] {
        case let .tag(count, tag):
            guard UserSetting.allow(remove: tag.name, controller: self) else {
                return
            }
            self.manager.select(tag: tag)

        case let .tagMore(type):
            return
        default:
            return
        }
    }
}

fileprivate class FilterBottomView: UIView {
    fileprivate let applyButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 3
        button.backgroundColor = .secondary500
        button.setTitleColor(.white, for: .normal)
        button.titleLabel!.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        return button
    }()
    fileprivate let indicator: NVActivityIndicatorView = {
        let indicator = NVActivityIndicatorView(frame: .zero, type: .ballBeat, color: .secondary500, padding: 4)
        indicator.stopAnimating()
        return indicator
    }()

    var count: Int? {
        didSet {
            if let count = count {
                self.indicator.stopAnimating()

                if count == 0 {
                    self.applyButton.setTitle("No Results".localized(), for: .normal)
                    self.applyButton.backgroundColor = .white
                    self.applyButton.setTitleColor(.secondary500, for: .normal)
                } else {
                    self.applyButton.setTitle(FilterManager.countTitle(count: count), for: .normal)
                    self.applyButton.backgroundColor = .secondary500
                    self.applyButton.setTitleColor(.white, for: .normal)
                }
            } else {
                self.indicator.startAnimating()
                self.applyButton.setTitle(nil, for: .normal)
                self.applyButton.backgroundColor = .white
            }
        }
    }

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.addSubview(applyButton)
        self.addSubview(indicator)

        applyButton.snp.makeConstraints { (make) in
            make.top.equalTo(self).inset(12)
            make.bottom.equalTo(self.safeArea.bottom).inset(12)
            make.right.left.equalTo(self).inset(24)
            make.height.equalTo(46)
        }

        indicator.snp.makeConstraints { make in
            make.edges.equalTo(applyButton)
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