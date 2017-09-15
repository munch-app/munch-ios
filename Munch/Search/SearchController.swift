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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Card Table View
        self.cardTableView.delegate = self
        self.cardTableView.dataSource = self
        
        self.cardTableView.rowHeight = UITableViewAutomaticDimension
        self.cardTableView.estimatedRowHeight = 44
        
        // TODO insets
        self.cardTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        registerCards()
        loadShimmerCards()
        
        // TODO Query place
    }
}

// CardType and tools
extension SearchController {
    func registerCards() {
        // Register Static Cards
        
        // Register Shimmer Cards
        
        // Register Dsicover Cards
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
        return 0
        // return cards.count
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
        return 16.0
    }
    
    var topBottom: CGFloat {
        return 8.0
    }
}
