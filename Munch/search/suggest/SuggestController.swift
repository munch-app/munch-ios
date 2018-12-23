//
// Created by Fuxing Loh on 21/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import Moya
import RxSwift
import RxCocoa

import FirebaseAnalytics

class SuggestRootController: UINavigationController, UINavigationControllerDelegate {
    init(searchQuery: SearchQuery, onDismiss: @escaping ((SearchQuery?) -> Void)) {
        super.init(nibName: nil, bundle: nil)
        let controller = SuggestController(searchQuery: searchQuery, onDismiss: onDismiss)
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

class SuggestController: UIViewController {
    private let onDismiss: ((SearchQuery?) -> Void)

    fileprivate let headerView = SuggestHeaderView()

    private let manager: SuggestManager
    private let disposeBag = DisposeBag()

    fileprivate let tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 56

        tableView.tableFooterView = UIView(frame: .zero)

        tableView.contentInset.top = 8
        tableView.contentInset.bottom = 8
        tableView.separatorStyle = .none
        return tableView
    }()

    private var items: [SuggestType] = []
    private var firstLoad: Bool = true

    init(searchQuery: SearchQuery, onDismiss: @escaping ((SearchQuery?) -> Void)) {
        self.manager = SuggestManager(searchQuery: searchQuery)
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
        self.registerCells()
        self.addTargets()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(tableView)
        self.view.addSubview(headerView)

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }

        self.tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.left.right.equalTo(self.view)
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

// MARK: Add Targets
extension SuggestController {
    func addTargets() {
        self.headerView.cancelButton.addTarget(self, action: #selector(onDismiss(button:)), for: .touchUpInside)

        self.manager.observe()
                .subscribe { event in
                    switch event {
                    case .next(let items):
                        self.items = items
                        self.tableView.reloadData()

                    case .error(let error):
                        self.alert(error: error)

                    case .completed:
                        return
                    }
                }
                .disposed(by: disposeBag)
        self.manager.start(textField: self.headerView.textField)
    }

    @objc func onDismiss(button: Any) {
        self.dismiss(animated: true)
    }
}

// MARK: TableView & ScrollView
extension SuggestController: UITableViewDataSource, UITableViewDelegate {
    func registerCells() {
        tableView.register(type: SuggestCellLoading.self)
        tableView.register(type: SuggestCellPlace.self)
        tableView.register(type: SuggestCellNoResult.self)
        tableView.register(type: SuggestCellSuggest.self)
        tableView.register(type: SuggestCellAssumption.self)
        tableView.register(type: SuggestCellQuery.self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.row] {
        case .place:
            return tableView.dequeue(type: SuggestCellPlace.self)

        case .loading:
            return tableView.dequeue(type: SuggestCellLoading.self)

        case .noResult:
            return tableView.dequeue(type: SuggestCellNoResult.self)

        case .suggest:
            return tableView.dequeue(type: SuggestCellSuggest.self)

        case .assumption:
            return tableView.dequeue(type: SuggestCellAssumption.self)

        case .query:
            return tableView.dequeue(type: SuggestCellQuery.self)
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch items[indexPath.row] {
        case .place(let place):
            let cell = cell as! SuggestCellPlace
            cell.render(place: place)

        case .suggest(let text):
            let cell = cell as! SuggestCellSuggest
            cell.suggest = text

        case .assumption(let result):
            let cell = cell as! SuggestCellAssumption
            cell.render(result: result)

        case let .query(tuple):
            let cell = cell as! SuggestCellQuery
            cell.render(with: tuple)

        default:
            return
        }
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch items[indexPath.row] {
        case .place(let place):
            let controller = RIPController(placeId: place.placeId)
            self.navigationController?.pushViewController(controller, animated: true)

        case .assumption(let result):
            self.onDismiss(result.searchQuery)
            self.dismiss(animated: true)

        case .suggest(let text):
            self.headerView.textField.text = text
            self.headerView.textField.sendActions(for: .valueChanged)

        case let .query(_, query):
            self.onDismiss(query)
            self.dismiss(animated: true)

        default:
            return
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.headerView.textField.resignFirstResponder()
    }
}

fileprivate class SuggestHeaderView: UIView {
    fileprivate let textField: MunchSearchTextField = {
        let textField = MunchSearchTextField()
        textField.placeholder = "Search \"Italian\""
        return textField
    }()
    fileprivate let cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("CANCEL", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        button.titleEdgeInsets.right = 24
        button.contentHorizontalAlignment = .right
        return button
    }()

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.addSubview(textField)
        self.addSubview(cancelButton)
        self.backgroundColor = .white

        textField.snp.makeConstraints { maker in
            maker.top.equalTo(self.safeArea.top).inset(12)
            maker.bottom.equalTo(self).inset(12)

            maker.left.equalTo(self).inset(24)
            maker.right.equalTo(cancelButton.snp.left)
            maker.height.equalTo(40)
        }

        cancelButton.snp.makeConstraints { maker in
            maker.width.equalTo(90)
            maker.right.equalTo(self)

            maker.top.bottom.equalTo(textField)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: 3)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}