//
//  DiscoverControllers.swift
//  Munch
//
//  Created by Fuxing Loh on 13/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class SearchController: UIViewController, UITableViewDelegate, UITableViewDataSource, SearchHeaderDelegate {
    @IBOutlet weak var cardTableView: UITableView!
    var headerView: SearchHeaderView!
    
    var collectionManager: SearchCollectionManager?
    
    var cards: [SearchCard] {
        if let manager = collectionManager {
            return manager.cards
        }
        let searchCard = SearchCard(cardId: SearchShimmerPlaceCard.cardId)
        return [searchCard, searchCard, searchCard]
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
        self.headerView = SearchHeaderView(controller: self)
        self.view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }
        
        // Setup Card Table View
        self.cardTableView.delegate = self
        self.cardTableView.dataSource = self
        
        self.cardTableView.rowHeight = UITableViewAutomaticDimension
        self.cardTableView.estimatedRowHeight = 50
        
        // Fix insets so that contents appear below
        self.cardTableView.contentInset = UIEdgeInsets(top: headerView.maxHeight - 20, left: 0, bottom: 0, right: 0)
        
        registerCards()
    }
    
    func scrollToTop() {
        cardTableView.setContentOffset(CGPoint.zero, animated: true)
    }
    
    /**
     If collectionManager is nil means show shimmer cards?
     */
    func headerView(render collectionManager: SearchCollectionManager?) {
        self.collectionManager = collectionManager
        self.cardTableView.reloadData()
    }
}

// CardType and tools
extension SearchController {
    func registerCards() {
        // Register Static Cards
        register(SearchStaticEmptyCard.self)
        register(SearchStaticNoResultCard.self)
        register(SearchStaticNoLocationCard.self)
        register(SearchStaticLoadingCard.self)
        
        // Register Shimmer Cards
        register(SearchShimmerPlaceCard.self)
        
        // Register Search Cards
        register(SearchPlaceCard.self)
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
        // let placeCard = cards[indexPath.row]
        // TODO: When cards have click features
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
        if let manager = self.collectionManager {
            manager.append(load: { meta in
                if (meta.isOk()) {
                    // Check reference is still the same
                    if (manager === self.collectionManager) {
                        self.cardTableView.reloadData()
                    }
                } else {
                    self.present(meta.createAlert(), animated: true)
                }
            })
        }
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
    
    static var card: SearchCard {
        return SearchCard(cardId: cardId)
    }
}
