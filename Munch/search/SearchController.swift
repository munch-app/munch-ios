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
    let searchTableView = SearchTableView(screen: .search)
    // SearchHeaderView.contentHeight
    //    let headerView = SearchHeaderView()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        self.cardTableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(searchTableView)

        searchTableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        self.searchTableView.cardDelegate = self
        self.searchTableView.search(screen: .search)
    }
}

extension SearchController: SearchTableViewDelegate {
    func searchTableView(didSelectCardAt card: SearchCard) {
//            let controller = PlaceController(place: place)
//            self.navigationController!.pushViewController(controller, animated: true)
    }

    func searchTableView(requireController: @escaping (UIViewController) -> Void) {
        requireController(self)
    }

    //        case .filter:
//            let controller = SearchFilterRootController(searchQuery: self.searchQuery, extensionDismiss: completable)
//            self.present(controller, animated: true)
//        case .suggest:
//            let controller = SearchSuggestRootController(searchQuery: self.searchQuery, extensionDismiss: completable)
//            self.present(controller, animated: true)
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

// MARK: Scroll View
extension SearchController {
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        self.headerView.contentDidScroll(scrollView: scrollView)
//    }
//
//    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        if (!decelerate) {
//            scrollViewDidFinish(scrollView)
//        }
//    }
//
//    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        scrollViewDidFinish(scrollView)
//    }
//
//    func scrollViewDidFinish(_ scrollView: UIScrollView) {
//        // Check nearest locate and move to it
//        if let y = self.headerView.contentShouldMove(scrollView: scrollView) {
//            let point = CGPoint(x: 0, y: y)
//            scrollView.setContentOffset(point, animated: true)
//        }
//    }
}