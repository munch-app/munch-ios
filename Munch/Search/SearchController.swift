//
//  DiscoverControllers.swift
//  Munch
//
//  Created by Fuxing Loh on 13/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit

class SearchNavigationalController: UINavigationController, UINavigationControllerDelegate {
    required init() {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [SearchController()]
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

class SearchController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let cardTableView = UITableView()
    let headerView = SearchHeaderView(showMapBtn: false)
    private let refreshControl = UIRefreshControl()

    private let backIndicatorView = BackIndicatorView()
    private var backIndicatorConstraint: Constraint!

    var cardManager: SearchCardManager?

    var searchQuery = SearchQuery()
    var cards: [SearchCard] {
        if let manager = cardManager {
            return manager.cards
        }
        let shimmerCard = SearchShimmerPlaceCard.card
        return [shimmerCard, shimmerCard, shimmerCard]
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
        self.initViews()
        self.registerCards()

        self.headerView.controller = self
        self.cardTableView.delegate = self
        self.cardTableView.dataSource = self

        // Render search results
        contentView(search: searchQuery)
        headerView.render(query: searchQuery)

        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
        edgePan.edges = .left
        self.view.addGestureRecognizer(edgePan)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Suggest Testing
//        self.goTo(extension: SearchSuggestController.self)
        // Place Testing
//         self.navigationController!.pushViewController(PlaceViewController(placeId: "9512d8fd-5123-49be-b223-5d7e469d28b7"), animated: true)
    }

    private func initViews() {
        self.view.addSubview(cardTableView)
        self.view.addSubview(headerView)
        self.view.addSubview(backIndicatorView)

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

        self.cardTableView.separatorStyle = .none
        self.cardTableView.showsVerticalScrollIndicator = false
        self.cardTableView.showsHorizontalScrollIndicator = false

        self.cardTableView.rowHeight = UITableViewAutomaticDimension
        self.cardTableView.estimatedRowHeight = 1000

        // Fix insets so that contents appear below
        self.cardTableView.contentInset.top = self.headerView.contentHeight
        self.cardTableView.contentInsetAdjustmentBehavior = .always

        // Add RefreshControl to CardTableView
        refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        refreshControl.tintColor = UIColor.black.withAlphaComponent(0.7)
        self.cardTableView.addSubview(refreshControl)
    }

    func scrollsToTop(animated: Bool = true) {
        // Scroll to content view
        cardTableView.scrollToRow(at: .init(row: 0, section: 0), at: .top, animated: animated)
    }

    func contentView(search searchQuery: SearchQuery, animated: Bool = true) {
        func resetView() {
            self.cardManager = nil
            self.cardTableView.reloadData()
            self.cardTableView.isScrollEnabled = false
            self.scrollsToTop(animated: animated)
        }

        func search(searchQuery: SearchQuery) {
            // Save a copy locally, cannot remove
            self.searchQuery = searchQuery
            // Reset ContentView first
            resetView()

            // 2 Seconds lag for all searches
            let deadline = DispatchTime.now() + 1.5
            self.cardManager = SearchCardManager(search: searchQuery, completion: { meta, manager in
                guard manager === self.cardManager else {
                    return // Card manager is not in context anymore
                }

                DispatchQueue.main.asyncAfter(deadline: deadline) {
                    self.cardTableView.isScrollEnabled = true
                    self.scrollsToTop(animated: animated)
                    self.cardTableView.reloadData()

                    // If error, show alert
                    guard meta.isOk() else {
                        self.present(meta.createAlert(), animated: true)
                        return
                    }
                }
            })
        }

        // Reset ContentView first
        resetView()
        search(searchQuery: searchQuery)
    }

    func reset() {
        if let time = cardManager?.time, time.addingTimeInterval(60 * 60) < Date() {
            // Query requires refresh as it expired in 1 hour
            searchQuery = SearchQuery()
            contentView(search: searchQuery)
            headerView.searchQueryHistories.removeAll()
            headerView.render(query: searchQuery)
        }
    }

    func render(searchQuery: SearchQuery) {
        self.contentView(search: searchQuery)
        self.headerView.render(query: searchQuery)
    }

    func goTo(extension type: UIViewController.Type) {
        if type == SearchSuggestController.self {
            let controller = SearchSuggestRootController(searchQuery: self.searchQuery) { searchQuery in
                if let searchQuery = searchQuery {
                    self.render(searchQuery: searchQuery)
                }
            }
            self.present(controller, animated: true)
        }
    }

    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.contentView(search: self.searchQuery)
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

// Card CollectionView
extension SearchController {
    private func registerCards() {
        func register(_ cellClass: SearchCardView.Type) {
            cardTableView.register(cellClass as? Swift.AnyClass, forCellReuseIdentifier: cellClass.cardId)
        }

        // Register Static Cards
        register(SearchStaticEmptyCard.self)
        register(SearchStaticTopCard.self)
        register(SearchStaticNoResultCard.self)
        register(SearchStaticLoadingCard.self)
        register(SearchStaticErrorCard.self)

        // Register Shimmer Cards
        register(SearchShimmerPlaceCard.self)

        // Register Search Cards
        register(SearchHeaderCard.self)
        register(SearchPlaceCard.self)
        register(SearchSmallPlaceCard.self)

        register(SearchContainersCard.self)
        register(SearchNewPlaceCard.self)
        register(SearchRecentPlaceCard.self)

        register(SearchNoLocationCard.self)
        register(SearchNoResultCard.self)
        register(SearchNoResultLocationCard.self)
        register(SearchQueryReplaceCard.self)
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
            // Index out of bound in debug mode
            if let card = cards.get(indexPath.row) {
                if let cardView = cardTableView.dequeueReusableCell(withIdentifier: card.cardId) {
                    return cardView
                }
            }
        case 2: // Loading card
            return cardTableView.dequeueReusableCell(withIdentifier: SearchStaticLoadingCard.cardId)!
        default: break
        }

        // Else Static Empty CardView
        return cardTableView.dequeueReusableCell(withIdentifier: SearchStaticEmptyCard.cardId)!
    }

    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 1:
            // Improve performance for this card
            if let card = cards.get(indexPath.row), card.cardId == SearchPlaceCard.cardId {
                return UIScreen.main.bounds.width * 0.888
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
            }
        case 2:
            self.appendLoad()
        default: break
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            let card = cards[indexPath.row]
            switch card.cardId {
            case SearchPlaceCard.cardId:
                fallthrough
            case SearchSmallPlaceCard.cardId:
                self.select(placeId: card["placeId"].string)
            default: break
            }
        default: break
        }
    }

    func select(placeId: String?) {
        if let placeId = placeId {
            DispatchQueue.main.async {
                let controller = PlaceViewController(placeId: placeId)
                self.navigationController!.pushViewController(controller, animated: true)
            }
        }
    }
}

// Lazy Append Loading
extension SearchController {
    func appendLoad() {
        if let manager = self.cardManager, manager.more {
            manager.append(load: { meta, manager in
                guard manager === self.cardManager else {
                    return // Card manager is not in context anymore
                }

                DispatchQueue.main.async {
                    // If error, error card will appear, no need to alert
                    if (manager.more) {
                        self.cardTableView.reloadData()
                    } else {
                        let cell = self.cardTableView.cellForRow(at: .init(row: 0, section: 2)) as? SearchStaticLoadingCard
                        cell?.stopAnimating()
                    }
                }
            })
        }
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