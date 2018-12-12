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
    private let searchTableView = SearchTableView(screen: .search, inset: inset)

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
        self.searchTableView.cardDelegate = self
        self.headerView.controller = self

        self.push(searchQuery: SearchQuery(feature: .Home))
    }

    var histories = [SearchQuery]()

    func push(searchQuery: SearchQuery) {
        histories.append(searchQuery)
        if !searchQuery.isSimple() {
            recent.add(id: String(arc4random()), data: searchQuery)
        }

        self.searchTableView.search(query: searchQuery, screen: .search)
        self.searchTableView.scrollsToTop()
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
            self.searchTableView.scrollsToTop()
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

extension SearchController: SearchTableViewDelegate {
    func searchTableView(didSelectCardAt card: SearchCard) {
        switch card.cardId {
        case SearchPlaceCard.cardId:
            if let place = card.decode(name: "place", Place.self) {
                let controller = RIPController(placeId: place.placeId)
                self.navigationController!.pushViewController(controller, animated: true)
            }

        default:
            return
        }
    }

    func searchTableView(requireController: @escaping (SearchController) -> Void) {
        requireController(self)
    }
}

// MARK: Search Query Rendering
extension SearchController {
//    private func runChecks() {
//        DispatchQueue.main.async {
//            if let tag = UserSetting.request(toPerm: self.searchQuery) {
//                let m1 = "Hi ".localized()
//                let m2 = ", we noticed you require ‘".localized()
//                let m3 = "’ food often. Would you like ‘".localized()
//                let m4 = "’ to be included in all future searches?\\n\\nDon’t worry, you may edit this from your profile if required.".localized()
//                let message = "\(m1)\(UserProfile.instance?.name ?? "")\(m2)\(tag.capitalized)\(m3)\(tag.capitalized)\(m4)"
//                let alert = UIAlertController(title: "Search Preference".localized(), message: message, preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
//                alert.addAction(UIAlertAction(title: "Add".localized(), style: .default) { action in
//                    Authentication.requireAuthentication(controller: self) { state in
//                        switch state {
//                        case .loggedIn:
//                            UserSetting.apply(search: { search in
//                                var search = search
//                                search.tags.append(tag.lowercased())
//                                return search
//                            }) { result in
//                                switch result {
//                                case .success:
//                                    let t1 = "Added '".localized()
//                                    let t2 = "' to Search Preference.".localized()
//                                    self.view.makeToast("\(t1)\(tag.capitalized)\(t2)", image: UIImage(named: "RIP-Toast-Checkmark"), style: DefaultToastStyle)
//                                case .error(let error):
//                                    self.alert(error: error)
//                                }
//                            }
//                        default:
//                            return
//                        }
//                    }
//                })
//                self.present(alert, animated: true)
//            }
//        }
//    }
}