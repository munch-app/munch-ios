//
// Created by Fuxing Loh on 2018-11-30.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import os.log

import Foundation
import UIKit
import SnapKit
import RxSwift

import FirebaseAnalytics

class SearchTableView: UITableView {
    private let disposeBag = DisposeBag()

    var cardManager: SearchCardManager
    var cardDelegate: SearchTableViewDelegate?
    var controller: SearchController!

    var cardIds = [String: SearchCardView.Type]()
    var cards = [SearchCard]()

    private let refreshView: UIRefreshControl = {
        let control = UIRefreshControl()
        control.tintColor = UIColor.secondary500
        return control
    }()

    required init(query: SearchQuery = SearchQuery(), inset: UIEdgeInsets = .zero) {
        self.cardManager = SearchCardManager(query: query)
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
            cardIds[cellClass.cardId] = cellClass
        }

        // Register Local Cards
        register(SearchStaticTopCard.self)
        register(SearchStaticNoResultCard.self)
        register(SearchStaticLoadingCard.self)
        register(SearchStaticErrorCard.self)
        register(SearchStaticUnsupportedCard.self)
        register(SearchShimmerPlaceCard.self)

        register(SearchNoLocationCard.self)
        register(SearchNoResultCard.self)

        register(SearchCardCollectionHeader.self)

        register(SearchCardHomeDTJE.self)

        register(SearchHomeTabCard.self)
        register(SearchHomeNearbyCard.self)
        register(SearchCardHomeRecentPlace.self)
        register(SearchCardHomePopularPlace.self)
        register(SearchCardHomeAwardCollection.self)

        register(SearchCardLocationBanner.self)
        register(SearchCardLocationArea.self)

        register(SearchCardBetweenHeader.self)

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
    func search(query: SearchQuery, animated: Bool = true) {
        self.cardManager = SearchCardManager(query: query)
        self.cardManager.start()
                .subscribe { event in
                    switch event {
                    case .next(let cards):
                        self.reloadData(cards: cards)

                    case .error:    fallthrough
                    case .completed:
                        self.loadingCard.stopAnimating()
                    }
                }
                .disposed(by: disposeBag)
    }

    func reloadData(cards: [SearchCard]) {
        self.cards = cards.filter { (card: SearchCard) -> Bool in
            if self.cardIds[card.cardId] != nil {
                return true
            }

            os_log("Required Card: %@ Not Found, SearchStaticEmptyCard is used instead", type: .info, card.cardId)
            return false
        }
        self.reloadData()
    }

    func scrollToTop(animated: Bool = true) {
        self.scrollToRow(at: .init(row: 0, section: 0), at: .top, animated: animated)
    }

    func scrollTo(uniqueId: String, animated: Bool = true) {
        guard let row = cards.firstIndex(where: { $0.uniqueId == uniqueId }) else {
            return
        }

        self.scrollToRow(at: .init(row: row, section: 1), at: .top, animated: animated)
    }

    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.search(query: self.cardManager.searchQuery)
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
        func dequeue(card: SearchCard) -> SearchCardView {
            let cardView = dequeueReusableCell(withIdentifier: card.cardId) as! SearchCardView
            cardView.register(card: card, controller: self.controller)
            return cardView
        }

        switch indexPath.section {
        case 0:
            return dequeue(card: SearchStaticTopCard.card)

        case 1:
            return dequeue(card: cards[indexPath.row])

        case 2:
            return self.loadingCard

        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 1:
            if let card = cards.get(indexPath.row), let type = cardIds[card.cardId] {
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
            guard let card = cards.get(indexPath.row) else {
                return
            }

            if let cardView = cell as? SearchCardView {
                cardView.willDisplay(card: card)
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
        guard let card = cards.get(indexPath.row) else {
            return
        }

        if let cardView = tableView.cellForRow(at: indexPath) as? SearchCardView {
            cardView.didSelect(card: card, controller: self.controller)
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
        guard cardManager.more else {
            self.loadingCard.stopAnimating()
            return
        }

        self.loadingCard.startAnimating()
        cardManager.append()
    }
}

extension SearchTableView {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.cardDelegate?.searchTableView(didScroll: self)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (!decelerate) {
            self.cardDelegate?.searchTableView(didScrollFinish: self)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.cardDelegate?.searchTableView(didScrollFinish: self)
    }
}