//
// Created by Fuxing Loh on 19/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import os.log

import Foundation
import UIKit
import Moya
import Localize_Swift
import RxSwift
import RxCocoa

import SnapKit
import FirebaseAnalytics

import Kingfisher
import FirebaseAuth

import Toast_Swift

class SearchRootController: UINavigationController, UINavigationControllerDelegate {
    let searchController = SearchController()

    required init() {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [searchController]
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
    let cardTableView: UITableView = {
        let cardTableView = UITableView()
        cardTableView.separatorStyle = .none
        cardTableView.showsVerticalScrollIndicator = false
        cardTableView.showsHorizontalScrollIndicator = false

        cardTableView.rowHeight = UITableViewAutomaticDimension
        cardTableView.estimatedRowHeight = 400

        // Fix insets so that contents appear below
        cardTableView.contentInset.top = SearchHeaderView.contentHeight
        cardTableView.contentInsetAdjustmentBehavior = .always
        return cardTableView
    }()
    let headerView = SearchHeaderView()
    var cardTypes = [String: SearchCardView.Type]()

    private let refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.tintColor = UIColor.black.withAlphaComponent(0.7)
        return control
    }()

    private let backIndicatorView = BackIndicatorView()
    private var backIndicatorConstraint: Constraint!

    var cardManager = SearchCardManager(searchQuery: SearchQuery())
    private(set) var searchQuery: SearchQuery {
        get {
            return cardManager.searchQuery
        }
        set(searchQuery) {
            self.cardManager = SearchCardManager(searchQuery: searchQuery)
            self.headerView.render(query: searchQuery)
        }
    }
    var cards: [SearchCard] {
        return cardManager.cards
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        if AccountRootBoardingController.toShow {
            self.present(AccountRootBoardingController(guestOption: true, withCompletion: { state in
                // Currently does nothing
            }), animated: true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.cardTableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(cardTableView)
        self.view.addSubview(headerView)
        self.view.addSubview(backIndicatorView)
        self.cardTableView.addSubview(refreshControl)
        cardTableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }

        backIndicatorView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).inset(-12)
            self.backIndicatorConstraint = make.left.equalTo(self.view).inset(-66).constraint
        }

        self.registerCards()
        self.registerControls()

        self.headerView.controller = self
        self.cardTableView.delegate = self
        self.cardTableView.dataSource = self

        self.search(searchQuery: self.searchQuery, animated: false)
    }

    func scrollsToTop(animated: Bool = true) {
        cardTableView.scrollToRow(at: .init(row: 0, section: 0), at: .top, animated: animated)
    }
}

extension SearchController {
    enum GoTo {
        case filter
        case suggest
        case place(Place)
    }

    func goTo(where goTo: GoTo) {
        func completable(searchQuery: SearchQuery?) {
            if let searchQuery = searchQuery {
                self.search(searchQuery: searchQuery)
            }
        }

        switch goTo {
        case .filter:
            let controller = SearchFilterRootController(searchQuery: self.searchQuery, extensionDismiss: completable)
            self.present(controller, animated: true)
        case .suggest:
            let controller = SearchSuggestRootController(searchQuery: self.searchQuery, extensionDismiss: completable)
            self.present(controller, animated: true)
        case .place(let place):
            let controller = PlaceController(place: place)
            self.navigationController!.pushViewController(controller, animated: true)
        }
    }
}

// MARK: Search Query Rendering
extension SearchController {
    func search(searchQuery: SearchQuery, animated: Bool = true) {
        // Reset Views
        self.searchQuery = searchQuery
        self.cardTableView.reloadData()
        self.scrollsToTop(animated: animated)

        self.cardManager.start {
            DispatchQueue.main.async {
                self.cardTableView.reloadData()
                self.runChecks()
            }
        }
    }

    func search(edit: @escaping(inout SearchQuery) -> Void) {
        var searchQuery = self.searchQuery
        edit(&searchQuery)
        search(searchQuery: searchQuery, animated: true)
    }

    private func runChecks() {
        DispatchQueue.main.async {
            if let tag = UserSetting.request(toPerm: self.searchQuery) {
                let m1 = "Hi ".localized()
                let m2 = ", we noticed you require ‘".localized()
                let m3 = "’ food often. Would you like ‘".localized()
                let m4 = "’ to be included in all future searches?\\n\\nDon’t worry, you may edit this from your profile if required.".localized()
                let message = "\(m1)\(UserProfile.instance?.name ?? "")\(m2)\(tag.capitalized)\(m3)\(tag.capitalized)\(m4)"
                let alert = UIAlertController(title: "Search Preference".localized(), message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Add".localized(), style: .default) { action in
                    Authentication.requireAuthentication(controller: self) { state in
                        switch state {
                        case .loggedIn:
                            UserSetting.apply(search: { search in
                                var search = search
                                search.tags.append(tag.lowercased())
                                return search
                            }) { result in
                                switch result {
                                case .success:
                                    let t1 = "Added '".localized()
                                    let t2 = "' to Search Preference.".localized()
                                    self.view.makeToast("\(t1)\(tag.capitalized)\(t2)", image: UIImage(named: "RIP-Toast-Checkmark"), style: DefaultToastStyle)
                                case .error(let error):
                                    self.alert(error: error)
                                }
                            }
                        default:
                            return
                        }
                    }
                })
                self.present(alert, animated: true)
            }
        }
    }

    func reset(force: Bool = false) {
        if force || cardManager.startDate.addingTimeInterval(60 * 60) < Date() {
            // Query requires refresh as it expired in 1 hour
            headerView.queryHistories.removeAll()
            search(searchQuery: SearchQuery())
        }
    }
}

// MARK: Refresh & Swipe Back
extension SearchController {
    private func registerControls() {
        refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)

        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped(_:)))
        edgePan.edges = .left
        self.view.addGestureRecognizer(edgePan)
    }

    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.search(searchQuery: searchQuery)
        refreshControl.endRefreshing()
    }

    @objc func screenEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        // Offset by 10
        func getIndicatorOffset() -> CGFloat {
            let x = recognizer.translation(in: self.view).x
            let actual = (x - 10.0) / 2.2
            return actual > 66.0 ? 0 : actual - 66.0
        }

        if self.headerView.hasPrevious() {
            switch recognizer.state {
            case .began:
                fallthrough
            case .changed:
                let offset = getIndicatorOffset()
                if offset == 0.0 && offset != backIndicatorConstraint.layoutConstraints[0].constant {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                backIndicatorConstraint.update(offset: offset)
                cardTableView.alpha = 0.6 + (-offset / 66.0) * 0.4
            case .ended:
                if (backIndicatorConstraint.layoutConstraints[0].constant == 0.0) {
                    self.headerView.renderPrevious()
                }
                fallthrough
            default:
                cardTableView.alpha = 1.0
                backIndicatorConstraint.update(offset: -66)
                return
            }
        }
    }

    fileprivate class BackIndicatorView: UIView {
        let imageView: UIImageView = {
            let imageView = UIImageView()
            imageView.tintColor = .black
            imageView.image = UIImage(named: "Search-Back")
            return imageView
        }()

        init() {
            super.init(frame: .zero)
            self.addSubview(imageView)
            self.backgroundColor = .white
            self.layer.cornerRadius = 3
            self.layer.masksToBounds = true

            imageView.snp.makeConstraints { make in
                make.height.width.equalTo(32)
                make.left.equalTo(self).inset(24)
                make.top.bottom.right.equalTo(self).inset(10)
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            self.shadow(width: 0, height: 0, radius: 3, opacity: 1.0)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

// MARK: Card CollectionView
extension SearchController: UITableViewDelegate, UITableViewDataSource {
    private func registerCards() {
        func register(_ cellClass: SearchCardView.Type) {
            cardTableView.register(cellClass as? Swift.AnyClass, forCellReuseIdentifier: cellClass.cardId)
            cardTypes[cellClass.cardId] = cellClass
        }

        // Register Local Cards
        register(SearchStaticEmptyCard.self)
        register(SearchStaticTopCard.self)
        register(SearchStaticNoResultCard.self)
        register(SearchStaticLoadingCard.self)
        register(SearchStaticErrorCard.self)
        register(SearchStaticUnsupportedCard.self)
        register(SearchShimmerPlaceCard.self)

        // Register Search Cards
        register(SearchHeaderCard.self)
        register(SearchPlaceCard.self)
        register(SearchSmallPlaceCard.self)

        register(SearchAreaClusterListCard.self)

        register(SearchNoLocationCard.self)
        register(SearchNoResultCard.self)
        register(SearchNoResultLocationCard.self)
        register(SearchQueryReplaceCard.self)

        // Register Top Cards
        register(SearchAreaClusterHeaderCard.self)

        // Register Middle Cards
        register(SearchCardSuggestionTag.self)
        register(SearchInstagramPartnerCard.self)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        // 1. Header:
        // 2. Content: Actual Cards
        // 3. Bottom: Loading Card
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return cards.count
        case 2: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return cardTableView.dequeueReusableCell(withIdentifier: SearchStaticTopCard.cardId)!
        case 1:
            if let card = cards.get(indexPath.row) {
                if let cardView = cardTableView.dequeueReusableCell(withIdentifier: card.cardId) {
                    return cardView
                }

                os_log("Required Card: %@ Not Found, SearchStaticEmptyCard is used instead", type: .info, card.cardId)
            }
        case 2: return loadingCell
        default: break
        }

        // Else Static Empty CardView
        return cardTableView.dequeueReusableCell(withIdentifier: SearchStaticEmptyCard.cardId)!
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 1:
            if let card = cards.get(indexPath.row), let type = cardTypes[card.cardId] {
                return type.height(card: card)
            }
        default: break
        }
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            if let card = cards.get(indexPath.row) {
                if let cell = cell as? SearchCardView {
                    cell.render(card: card, controller: self)
                }

                Analytics.logEvent(AnalyticsEventViewItem, parameters: [
                    AnalyticsParameterItemID: "card-\(card.uniqueId ?? "")" as NSObject,
                    AnalyticsParameterItemCategory: card.cardId as NSObject
                ])
            }
        case 2: self.appendLoad()
        default: break
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let card = cards[indexPath.row]
        switch (indexPath.section, card.cardId) {
        case (1, SearchPlaceCard.cardId):
            fallthrough
        case (1, SearchSmallPlaceCard.cardId):
            if let place = card.decode(name: "place", Place.self) {
                Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                    AnalyticsParameterItemID: "place-\(place.placeId)" as NSObject,
                    AnalyticsParameterContentType: "search_place" as NSObject
                ])

                self.goTo(where: .place(place))
            }
        default: break
        }
    }
}

/*
extension SearchController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        DispatchQueue.global(qos: .background).async {
            let imageList: [[String: String]] = indexPaths.filter({ $0.section == 1 })
                    .compactMap({
                        if let card = self.cards.get($0.row) {
                            if let images = card.dict(name: "images") as? [[String: Any]], let image = images.get(0) {
                                return image["images"] as? [String: String]
                            }
                        }
                        return nil
                    })

            MunchImageView.prefetch(imageList: imageList, size: self.imageSize)
        }
    }
}
*/

// MARK: Lazy Append Loading
extension SearchController {
    private static let loadingCell: SearchStaticLoadingCard = SearchStaticLoadingCard()
    private var loadingCell: SearchStaticLoadingCard {
        return SearchController.loadingCell
    }

    /// loadingCell need to be passed in because it might but be ready yet
    private func appendLoad() {
        if self.cardManager.more {
            self.cardManager.append {
                self.reloadData()
            }
        } else {
            loadingCell.stopAnimating()
        }
    }

    func reloadData() {
        self.cardTableView.reloadData()

        guard self.cardManager.more else {
            return
        }
        self.loadingCell.stopAnimating()
    }
}

// MARK: Scroll View
extension SearchController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.headerView.contentDidScroll(scrollView: scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (!decelerate) {
            scrollViewDidFinish(scrollView)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidFinish(scrollView)
    }

    func scrollViewDidFinish(_ scrollView: UIScrollView) {
        // Check nearest locate and move to it
        if let y = self.headerView.contentShouldMove(scrollView: scrollView) {
            let point = CGPoint(x: 0, y: y)
            scrollView.setContentOffset(point, animated: true)
        }
    }
}