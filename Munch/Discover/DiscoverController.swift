//
//  DiscoverControllers.swift
//  Munch
//
//  Created by Fuxing Loh on 13/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class DiscoverController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var cardTableView: UITableView!
    var collections = [SearchCollection]()
    var results = [SearchResult]()
    
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
    
    private func loadShimmerCards() {
        cards.append(PlaceCard(id: DiscoverShimmerPlaceCard.id))
        cards.append(PlaceCard(id: DiscoverShimmerPlaceCard.id))
        cards.append(PlaceCard(id: DiscoverShimmerPlaceCard.id))
        cardTableView.reloadData()
    }
}

// CardType and tools
extension DiscoverController {
    func registerCards() {
        // Register Static Cards
        
        // Register Shimmer Cards
        
        // Register Dsicover Cards
    }
    
    private func register(_ cellClass: DiscoverCardView.Type) {
        cardTableView.register(cellClass as? Swift.AnyClass, forCellReuseIdentifier: cellClass.id)
    }
}

// Card CollectionView
extension DiscoverController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
        // return cards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let placeCard = cards[indexPath.row]
        
        if let cardView = cardTableView.dequeueReusableCell(withIdentifier: placeCard.id) as? PlaceCardView {
            cardView.render(card: placeCard)
            return cardView as! UITableViewCell
        }
        
        // Static Empty CardView
        return cardTableView.dequeueReusableCell(withIdentifier: PlaceStaticEmptyCard.id)!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // let placeCard = cards[indexPath.row]
        // TODO: When cards have click features
    }
}

protocol DiscoverCardView {
    func render(card: PlaceCard)
    
    var leftRight: CGFloat { get }
    var topBottom: CGFloat { get }
    
    static var id: String { get }
}

extension DiscoverCardView {
    var leftRight: CGFloat {
        return 16.0
    }
    
    var topBottom: CGFloat {
        return 8.0
    }
}
