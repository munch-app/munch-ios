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
    var collections = [SearchCollection]()
    var cards = [SearchCard]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Card Table View
        self.cardTableView.delegate = self
        self.cardTableView.dataSource = self
        
        self.cardTableView.rowHeight = UITableViewAutomaticDimension
        self.cardTableView.estimatedRowHeight = 50
        
        // TODO insets
        self.cardTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        registerCards()
        loadShimmerCards()
        
        MunchApi.search.collections(query: SearchQuery()) { meta, collections in
            if (meta.isOk()) {
                // TODO
                if let cards = collections.get(0)?.cards {
                    self.cards = cards
                }
                self.cardTableView.reloadData()
            } else {
                self.present(meta.createAlert(), animated: true)
            }
        }
    }
    
    func scrollToTop() {
        cardTableView.setContentOffset(CGPoint.zero, animated: true)
    }
}

// CardType and tools
extension SearchController {
    func registerCards() {
        // Register Static Cards
        register(SearchStaticNoResultCard.self)
        register(SearchStaticNoLocationCard.self)
        
        // Register Shimmer Cards
        register(SearchShimmerPlaceCard.self)
        
        // Register Search Cards
        register(SearchPlaceCard.self)
    }
    
    func loadShimmerCards() {
        cards.append(SearchCard(cardId: SearchShimmerPlaceCard.cardId))
        cards.append(SearchCard(cardId: SearchShimmerPlaceCard.cardId))
        cards.append(SearchCard(cardId: SearchShimmerPlaceCard.cardId))
        cardTableView.reloadData()
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
        
        // Static Empty CardView
        return cardTableView.dequeueReusableCell(withIdentifier: SearchStaticEmptyCard.cardId)!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // let placeCard = cards[indexPath.row]
        // TODO: When cards have click features
    }
}

protocol SearchCardView {
    func render(card: SearchCard)
    
    var leftRight: CGFloat { get }
    var topBottom: CGFloat { get }
    
    static var cardId: String { get }
}

extension SearchCardView {
    var leftRight: CGFloat {
        return 24.0
    }
    
    var topBottom: CGFloat {
        return 16.0
    }
}
