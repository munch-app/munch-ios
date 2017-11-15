//
//  DiscoverControllers.swift
//  Munch
//
//  Created by Fuxing Loh on 13/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class SearchController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var cardTableView: UITableView!
    var headerView: SearchHeaderView!

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

        // self.performSegue(withIdentifier: "SearchHeaderView_filter", sender: self)
        // Place Testing
//        let storyboard = UIStoryboard(name: "Place", bundle: nil)
//        let controller = storyboard.instantiateInitialViewController() as! PlaceViewController
//        controller.placeId = "6f213bc4-cc00-4d89-9249-93f6c193939d"
//        self.navigationController!.pushViewController(controller, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.headerView = SearchHeaderView(controller: self)
        self.view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }

        // Setup Card Table View
        self.cardTableView.separatorStyle = .none
        self.cardTableView.showsVerticalScrollIndicator = false
        self.cardTableView.showsHorizontalScrollIndicator = false
        self.cardTableView.delegate = self
        self.cardTableView.dataSource = self

        self.cardTableView.rowHeight = UITableViewAutomaticDimension
        self.cardTableView.estimatedRowHeight = 1000

        // Fix insets so that contents appear below
        self.cardTableView.contentInset = UIEdgeInsets(top: headerView.maxHeight - 20, left: 0, bottom: 0, right: 0)

        registerCards()

        // Render search results
        contentView(search: searchQuery)
        headerView.render(query: searchQuery)
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
        func search(searchQuery: SearchQuery) {
            // Save a copy locally, cannot remove
            self.searchQuery = searchQuery
            self.cardManager = nil
            self.cardTableView.reloadData()
            self.cardTableView.isScrollEnabled = false
            self.scrollsToTop(animated: animated)

            self.cardManager = SearchCardManager.init(search: searchQuery, completion: { (meta) in
                if (meta.isOk()) {
                    self.cardTableView.reloadData()
                    self.cardTableView.isScrollEnabled = true
                    self.scrollsToTop(animated: animated)
                } else  {
                    self.present(meta.createAlert(), animated: true)
                }
            })
        }

        // Check if Location is Enabled
        if MunchLocation.isEnabled {
            MunchLocation.waitFor(completion: { latLng, error in
                if let latLng = latLng {
                    var updatedQuery = searchQuery
                    updatedQuery.latLng = latLng
                    search(searchQuery: updatedQuery)
                } else if let error = error {
                    self.alert(title: "Location Error", error: error)
                } else {
                    self.alert(title: "Location Error", message: "No Error or Location Data")
                }
            })
        } else {
            search(searchQuery: searchQuery)
        }
    }
}

// CardType and tools
extension SearchController {
    func registerCards() {
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

    private func register(_ cellClass: SearchCardView.Type) {
        cardTableView.register(cellClass as? Swift.AnyClass, forCellReuseIdentifier: cellClass.cardId)
    }
}

// Card CollectionView
extension SearchController {
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
            let storyboard = UIStoryboard(name: "Place", bundle: nil)
            let controller = storyboard.instantiateInitialViewController() as! PlaceViewController
            controller.placeId = placeId

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
