//
// Created by Fuxing Loh on 2018-11-30.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import os.log

import Foundation
import UIKit
import SnapKit

import FirebaseAnalytics

class SearchTableView: UITableView {
    var cardManager: SearchCardManager
    var cardDelegate: SearchTableViewDelegate!

    var cardTypes = [String: SearchCardView.Type]()
    var cards: [SearchCard] {
        if self.cardManager.cards.isEmpty {
            return [
                SearchShimmerPlaceCard.card,
                SearchShimmerPlaceCard.card,
                SearchShimmerPlaceCard.card,
            ]
        }

        return self.cardManager.cards
    }

    private let refreshView: UIRefreshControl = {
        let control = UIRefreshControl()
        control.tintColor = UIColor.secondary500
        return control
    }()

    required init(query: SearchQuery = SearchQuery(), screen: SearchScreen, inset: UIEdgeInsets = .zero) {
        self.cardManager = SearchCardManager(query: query, screen: screen)
        super.init(frame: .zero, style: .plain)

        self.contentInset = inset
        self.delegate = self
        self.dataSource = self

        self.addSubview(refreshView)
        self.refreshView.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)

        self.separatorStyle = .none
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false

        self.rowHeight = UITableViewAutomaticDimension
        self.estimatedRowHeight = 400

        self.contentInsetAdjustmentBehavior = .always

        self.registerAll()
    }

    private func registerAll() {
        func register(_ cellClass: SearchCardView.Type) {
            self.register(cellClass as? Swift.AnyClass, forCellReuseIdentifier: cellClass.cardId)
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

        register(SearchNoLocationCard.self)
        register(SearchNoResultCard.self)
        register(SearchNoResultLocationCard.self)

        register(SearchHomeTabCard.self)

        register(SearchHeaderCard.self)
        register(SearchPlaceCard.self)

        register(SearchAreaClusterListCard.self)
        register(SearchAreaClusterHeaderCard.self)
        register(SearchTagSuggestion.self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol SearchTableViewDelegate {
    func searchTableView(didSelectCardAt card: SearchCard)

    func searchTableView(requireController: @escaping (SearchController) -> Void)

    func searchTableView(didScroll searchTableView: SearchTableView)

    func searchTableView(didScrollFinish searchTableView: SearchTableView)
}

extension SearchTableViewDelegate {
    func searchTableView(didScroll searchTableView: SearchTableView) {
    }

    func searchTableView(didScrollFinish searchTableView: SearchTableView) {
    }
}

extension SearchTableView {
    func search(query: SearchQuery, screen: SearchScreen, animated: Bool = true) {
        self.cardManager = SearchCardManager(query: query, screen: screen)
        self.reloadData()

        self.cardManager.start {
            self.reloadData()
        }
    }

    func scrollsToTop(animated: Bool = true) {
        self.scrollToRow(at: .init(row: 0, section: 0), at: .top, animated: animated)
    }

    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.search(query: self.cardManager.searchQuery, screen: self.cardManager.searchScreen)
        refreshControl.endRefreshing()
    }
}

// MARK: Delegate & DataSource
extension SearchTableView: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        // 1. Header: ?
        // 2. Content: From API
        // 3. Bottom: Lazy Loading
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
            return dequeueReusableCell(withIdentifier: SearchStaticTopCard.cardId)!

        case 1:
            if let card = cards.get(indexPath.row) {
                if let cardView = dequeueReusableCell(withIdentifier: card.cardId) {
                    return cardView
                }

                os_log("Required Card: %@ Not Found, SearchStaticEmptyCard is used instead", type: .info, card.cardId)
            }

        case 2:
            return self.loadingCard

        default:
            break
        }

        // Else Static Empty CardView
        return dequeueReusableCell(withIdentifier: SearchStaticEmptyCard.cardId)!
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 1:
            if let card = cards.get(indexPath.row), let type = cardTypes[card.cardId] {
                return type.height(card: card)
            }

        default:
            break
        }
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            if let card = cards.get(indexPath.row) {
                if let cardView = cell as? SearchCardView {
                    cardView.render(card: card, delegate: self.cardDelegate)
                }
            }

        case 2:
            self.appendLoad()

        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else {
            return
        }

        if let card = cards.get(indexPath.row) {
            cardDelegate?.searchTableView(didSelectCardAt: card)
        }
    }
}

// MARK: Lazy Append Loading
extension SearchTableView {
    private static let loadingCard: SearchStaticLoadingCard = SearchStaticLoadingCard()
    private var loadingCard: SearchStaticLoadingCard {
        return SearchTableView.loadingCard
    }

    private func appendLoad() {
        if cardManager.more {
            cardManager.append {
                self.reloadData()

                // Must call class to get instance in-case of concurrently mutated away
                if self.cardManager.more {
                    return
                }
                self.loadingCard.stopAnimating()
            }
        } else {
            self.loadingCard.stopAnimating()
        }
    }
}

extension SearchTableView {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.cardDelegate.searchTableView(didScroll: self)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (!decelerate) {
            self.cardDelegate.searchTableView(didScrollFinish: self)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.cardDelegate.searchTableView(didScrollFinish: self)
    }
}