//
// Created by Fuxing Loh on 19/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Localize_Swift

import SafariServices

import Moya
import RxSwift
import RxCocoa

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
    private let edgeBackGesture = UIScreenEdgePanGestureRecognizer()
    private var edgeCrossed = false

    private let headerView = SearchHeaderView()
    private let recent = RecentSearchQueryDatabase()
    public let searchTableView = SearchTableView()

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

        self.addGesture()
        self.searchTableView.controller = self
        self.searchTableView.cardDelegate = self
        self.headerView.controller = self

        self.headerView.mode = .full
        self.searchTableView.contentInset.top = SearchHeaderView.height

        self.push(searchQuery: SearchQuery(feature: .Home))
    }

    var histories = [SearchQuery]()

    var searchQuery: SearchQuery {
        return histories.last!
    }

    var qid: String? {
        return self.searchTableView.cardManager.qid
    }

    func push(searchQuery: SearchQuery) {
        histories.append(searchQuery)
        if !searchQuery.isSimple() {
            recent.add(id: String(arc4random()), data: searchQuery)
        }

        search(searchQuery: searchQuery)
    }

    func push(edit: @escaping (inout SearchQuery) -> Void) {
        var searchQuery = self.histories.last!
        edit(&searchQuery)
        self.push(searchQuery: searchQuery)
    }

    func pop() {
        if histories.popLast() != nil, let searchQuery = histories.last {
            search(searchQuery: searchQuery)
        }
    }

    private func search(searchQuery: SearchQuery) {
        self.searchTableView.scrollToTop(animated: false)
        self.setNeedsStatusBarAppearanceUpdate()

        self.searchTableView.search(query: searchQuery)
        self.headerView.searchQuery = searchQuery

        MunchAnalytic.logSearchQuery(searchQuery: searchQuery)
    }

    func reset() {
        histories.removeAll()
        push(searchQuery: SearchQuery(feature: .Home))
    }
}

extension SearchController: UIGestureRecognizerDelegate {
    func addGesture() {
        edgeBackGesture.edges = .left
        edgeBackGesture.delegate = self
        edgeBackGesture.addTarget(self, action: #selector(panEdge(sender:)))

        self.view.addGestureRecognizer(edgeBackGesture)
        self.view.backgroundColor = .white

        let imageView = UIImageView()
        imageView.image = UIImage(named: "NavigationBar-Back")
        imageView.tintColor = .black

        self.view.addSubview(imageView)
        self.view.sendSubview(toBack: imageView)
        imageView.snp.makeConstraints { maker in
            maker.width.height.equalTo(32)
            maker.left.equalTo(self.view).inset(24)
            maker.centerY.equalTo(self.view)
        }
    }

    @objc func panEdge(sender: UIScreenEdgePanGestureRecognizer) {
        let translation = sender.translation(in: sender.view!)

        print(translation)

        switch (sender.state) {
        case .possible: fallthrough
        case .began:
            edgeCrossed = false

        case .changed:
            self.searchTableView.frame.origin.x = translation.x

            if (!edgeCrossed) {
                if (translation.x >= 80) {
                    edgeCrossed = true
                    UIImpactFeedbackGenerator().impactOccurred()
                }
            } else {
                if (translation.x < 80) {
                    edgeCrossed = false
                    UIImpactFeedbackGenerator().impactOccurred()
                }
            }

        case .ended:
            if (edgeCrossed) {
                self.pop()
            }
            self.searchTableView.frame.origin.x = 0
                // Apply

        case .failed: fallthrough
        case .cancelled:
            self.searchTableView.frame.origin.x = 0
        }
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return self.histories.count > 1
    }
}

extension SearchController: SearchTableViewDelegate {
    func searchTableView(didReload searchTableView: SearchTableView) {
        self.setNeedsStatusBarAppearanceUpdate()
    }

    func searchTableView(didScroll searchTableView: SearchTableView) {
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}

extension SearchController: SFSafariViewControllerDelegate {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MunchAnalytic.setScreen("/search")

        func showGiveFeedback() {
            MunchAnalytic.logEvent("notify_show_feedback")

            self.show(title: "Feed us with feedback", message: "Take a minute to tell us how to better serve you.", buttonTitle: "Give Feedback") {
                let safari = SFSafariViewController(url: URL(string: "https://airtable.com/shrp2EgmOUwshSZ3a")!)
                safari.delegate = self

                UserDefaults.count(key: .countGiveFeedback)
                MunchAnalytic.logEvent("notify_click_feedback")
                self.present(safari, animated: true, completion: nil)
            }
        }

        DispatchQueue.main.async {
            let openApp = UserDefaults.get(count: .countOpenApp)

            if openApp > 2 {
                UserDefaults.notify(key: .notifyGiveFeedbackV1) {
                    showGiveFeedback()
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    let countGive = UserDefaults.get(count: .countGiveFeedback)
                    if openApp > 4 && countGive == 0 {
                        UserDefaults.notify(key: .notifyGiveFeedbackV2) {
                            showGiveFeedback()
                        }
                    }
                }
            }
        }

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

    @objc func applicationWillEnterForeground(_ notification: NSNotification) {
        if let date = UserDefaults.standard.object(forKey: UserDefaultsKey.globalResignActiveDate.rawValue) as? Date {
            if Date().millis - date.millis > 1000 * 60 * 60 {
                self.reset()
            }
        }
    }
}