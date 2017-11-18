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

class SearchController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var cardTableView: UITableView!
    var headerView: SearchHeaderView!
    let refreshControl = UIRefreshControl()

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Filter Testing
        // self.performSegue(withIdentifier: "SearchHeaderView_filter", sender: self)
        // Place Testing
//         let controller = PlaceViewController(placeId: "8759e8cb-a52e-40e4-b75c-a65c9b089f23")
//         self.navigationController!.pushViewController(controller, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()
        self.registerCards()

        self.cardTableView.delegate = self
        self.cardTableView.dataSource = self

        // Render search results
        contentView(search: searchQuery)
        headerView.render(query: searchQuery)
    }

    private func initViews() {
        self.headerView = SearchHeaderView(controller: self)
        self.view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }

        self.cardTableView.separatorStyle = .none
        self.cardTableView.showsVerticalScrollIndicator = false
        self.cardTableView.showsHorizontalScrollIndicator = false

        self.cardTableView.rowHeight = UITableViewAutomaticDimension
        self.cardTableView.estimatedRowHeight = 1000

        // Fix insets so that contents appear below
        self.cardTableView.contentInset.top = headerView.maxHeight - 20


        refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        refreshControl.tintColor = UIColor.black.withAlphaComponent(0.7)
        self.cardTableView.addSubview(refreshControl)
    }


    func scrollsToTop(animated: Bool = true) {
        cardTableView.scrollToRow(at: .init(row: 0, section: 0), at: .top, animated: animated)
    }

    @IBAction func unwindToSearch(segue: UIStoryboardSegue) {
        func render(query: SearchQuery) {
            contentView(search: query)
            headerView.render(query: query)
        }

        let controller = segue.source
        if let query = controller as? SearchSuggestController {
            render(query: query.searchQuery)
        } else if let filter = controller as? SearchFilterController {
            render(query: filter.searchQuery)
        } else if let location = controller as? SearchLocationController {
            render(query: location.searchQuery)
        }
    }

    func contentView(search searchQuery: SearchQuery, animated: Bool = true) {
        func reset() {
            self.cardManager = nil
            self.cardTableView.reloadData()
            self.cardTableView.isScrollEnabled = false
            self.scrollsToTop(animated: animated)
        }

        func search(searchQuery: SearchQuery) {
            // Save a copy locally, cannot remove
            self.searchQuery = searchQuery
            // Reset ContentView first
            reset()

            self.cardManager = SearchCardManager.init(search: searchQuery, completion: { (meta) in
                if (meta.isOk()) {
                    self.cardTableView.reloadData()
                    self.cardTableView.isScrollEnabled = true
                    self.scrollsToTop(animated: animated)
                } else {
                    self.present(meta.createAlert(), animated: true)
                }
            })
        }

        // Reset ContentView first
        reset()
        // Check if Location is Enabled
        if MunchLocation.isEnabled {
            MunchLocation.waitFor(completion: { latLng, error in
                if let error = error {
                    self.alert(title: "Location Error", error: error)
                } else if let latLng = latLng {
                    var updatedQuery = searchQuery
                    updatedQuery.latLng = latLng
                    search(searchQuery: updatedQuery)
                } else {
                    self.alert(title: "Location Error", message: "No Error or Location Data")
                }
            })
        } else {
            search(searchQuery: searchQuery)
        }
    }

    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.contentView(search: self.searchQuery)
        refreshControl.endRefreshing()
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
        register(SearchStaticNoResultCard.self)
        register(SearchStaticLoadingCard.self)

        // Register Shimmer Cards
        register(SearchShimmerPlaceCard.self)

        // Register Search Cards
        register(SearchPlaceCard.self)
        register(SearchNoLocationCard.self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cards.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let card = cards[indexPath.row]

        if let cardView = cardTableView.dequeueReusableCell(withIdentifier: card.cardId) as? SearchCardView {
            cardView.render(card: card)
            return cardView as! UITableViewCell
        }

        // Else Static Empty CardView
        return cardTableView.dequeueReusableCell(withIdentifier: SearchStaticEmptyCard.cardId)!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let card = cards[indexPath.row]

        if card.cardId == SearchPlaceCard.cardId, let placeId = card["placeId"].string {
            // Place Card
            let controller = PlaceViewController(placeId: placeId)
            self.navigationController!.pushViewController(controller, animated: true)
        }
    }
}

// Lazy Append Loading
extension SearchController {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let card = cards[indexPath.row]

        if card.cardId == SearchStaticLoadingCard.cardId {
            DispatchQueue.main.async {
                self.appendLoad()
            }
        }
    }

    func appendLoad() {
        if let manager = self.cardManager {
            manager.append(load: { meta in
                if (meta.isOk()) {
                    // Check reference is still the same
                    if (manager === self.cardManager) {
                        self.cardTableView.reloadData()
                    }
                } else {
                    self.present(meta.createAlert(), animated: true)
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
            cardTableView.setContentOffset(point, animated: true)
        }
    }
}
