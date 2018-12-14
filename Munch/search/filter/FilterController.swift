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
        self.bottomView.state = .loading

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

                        if let count = self.manager.result?.count {
                            self.bottomView.state = .count(count)
                            self.indicator.isHidden = true
                        } else {
                            self.bottomView.state = .loading
                            self.indicator.isHidden = false
                        }
                    case .error(let error):
                        self.alert(error: error)

                    case .completed:
                        return
                    }
                }.disposed(by: disposeBag)
        self.manager.dispatch(delay: 0)
    }

    @objc func actionCancel(_ sender: Any) {
        self.dismiss(query: nil)
    }

    @objc func actionApply(_ sender: Any) {
        guard let count = manager.result?.count, count > 0 else {
            return
        }

        self.dismiss(query: manager.searchQuery)
    }

    func dismiss(query: SearchQuery?) {
        self.onDismiss(query)
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
            guard UserSearchPreference.allow(remove: tag) else {
                let alert = UIAlertController(title: "Tastebud Preference Note", message: "You have permanently enabled this filter. Please remove the filter from your Tastebud Preferences.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
                present(alert, animated: true)
                return
            }

            self.manager.select(tag: tag)

            if UserSearchPreference.prompt(tag: tag) {
                let alert = UIAlertController(title: "Tastebud Preference Note", message: "We noticed you require \(tag.name) as a dietary requirement. Would you like to apply this to all future searches?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
                present(alert, animated: true)
            }


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

    enum State {
        case count(Int)
        case loading
    }

    var state: State = .loading {
        didSet {
            switch state {
            case .count(let count) where count == 0:
                self.applyButton.setTitle("No Results", for: .normal)
                self.applyButton.backgroundColor = .secondary050
                self.applyButton.setTitleColor(.secondary700, for: .normal)

            case .count(let count) where count > 0:
                self.applyButton.setTitle(FilterManager.countTitle(count: count), for: .normal)
                self.applyButton.backgroundColor = .secondary500
                self.applyButton.setTitleColor(.white, for: .normal)

            default:
                self.applyButton.setTitle(nil, for: .normal)
                self.applyButton.backgroundColor = .secondary050
            }
        }
    }

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.addSubview(applyButton)

        applyButton.snp.makeConstraints { (make) in
            make.top.equalTo(self).inset(12)
            make.bottom.equalTo(self.safeArea.bottom).inset(12)
            make.right.left.equalTo(self).inset(24)
            make.height.equalTo(46)
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