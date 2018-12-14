//
// Created by Fuxing Loh on 19/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Localize_Swift

import Moya
import RxSwift
import RxCocoa

import FirebaseAnalytics
import Kingfisher
import FirebaseAuth
import Toast_Swift

class SearchRootController: UINavigationController, UINavigationControllerDelegate {
    let controller = SearchController()

    required init() {
        super.init(nibName: nil, bundle: nil)
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

class SearchController: UIViewController {
    static let inset = UIEdgeInsets(top: SearchHeaderView.height, left: 0, bottom: 0, right: 0)

    private let headerView = SearchHeaderView()
    private let recent = RecentSearchQueryDatabase()
    public let searchTableView = SearchTableView(screen: .search, inset: inset)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(searchTableView)
        self.view.addSubview(headerView)

        headerView.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(self.view)
        }

        searchTableView.snp.makeConstraints { maker in
            maker.edges.equalTo(self.view)
        }

        self.searchTableView.controller = self
        self.headerView.controller = self

        self.push(searchQuery: SearchQuery(feature: .Home))
    }

    var histories = [SearchQuery]()

    var searchQuery: SearchQuery {
        return histories.last!
    }

    func push(searchQuery: SearchQuery) {
        histories.append(searchQuery)
        if !searchQuery.isSimple() {
            recent.add(id: String(arc4random()), data: searchQuery)
        }

        self.searchTableView.search(query: searchQuery, screen: .search)
        self.searchTableView.scrollToTop()
        self.headerView.searchQuery = searchQuery
    }

    func push(edit: @escaping (inout SearchQuery) -> Void) {
        var searchQuery = self.histories.last!
        edit(&searchQuery)
        self.push(searchQuery: searchQuery)
    }

    func pop() {
        if histories.popLast() != nil, let searchQuery = histories.last {
            self.searchTableView.search(query: searchQuery, screen: .search)
            self.searchTableView.scrollToTop()
            self.headerView.searchQuery = searchQuery
        }
    }

    func reset() {
        histories.removeAll()
        push(searchQuery: SearchQuery(feature: .Home))
    }
}

extension SearchController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let center = NotificationCenter.default
        center.addObserver(self,
                selector: #selector(applicationWillEnterForeground(_:)),
                name: NSNotification.Name.UIApplicationWillEnterForeground,
                object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let center = NotificationCenter.default
        center.removeObserver(self,
                name: NSNotification.Name.UIApplicationWillEnterForeground,
                object: nil)
    }

    func applicationWillEnterForeground(_ notification: NSNotification) {
        if let date = UserDefaults.standard.object(forKey: UserDefaults.Key.globalResignActiveDate) as? Date {
            if Date().millis - date.millis > 1000 * 60 * 60 {
                self.reset()
            }
        }
    }
}