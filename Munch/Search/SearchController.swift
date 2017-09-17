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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(false, animated: false)
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
        
        // TODO insets
        self.cardTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        registerCards()
    }
    
    func scrollToTop() {
        cardTableView.setContentOffset(CGPoint.zero, animated: true)
    }
    
    /**
     If collectionManager is nil means show shimmer cards?
     */
    func headerView(render collectionManager: SearchCollectionManager?) {
        
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

    private func register(_ cellClass: SearchCardView.Type) {
        cardTableView.register(cellClass as? Swift.AnyClass, forCellReuseIdentifier: cellClass.cardId)
    }
}

// Card CollectionView
extension SearchController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let manager = collectionManager {
            return manager.cards.count
        }
        // Else show 2 shimmer card
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let manager = collectionManager {
            let card = manager.cards[indexPath.row]
            
            if let cardView = cardTableView.dequeueReusableCell(withIdentifier: card.cardId) as? SearchCardView {
                cardView.render(card: card)
                return cardView as! UITableViewCell
            }
            
            // Else Static Empty CardView
            return cardTableView.dequeueReusableCell(withIdentifier: SearchStaticEmptyCard.cardId)!
        } else {
            // Else show shimmer card
            return cardTableView.dequeueReusableCell(withIdentifier: SearchShimmerPlaceCard.cardId)!
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // let placeCard = cards[indexPath.row]
        // TODO: When cards have click features
    }
}

// Lazy Append Loading
extension SearchController {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let manager = collectionManager {
            let card = manager.cards[indexPath.row]
            
            if card.cardId == SearchStaticLoadingCard.cardId {
                DispatchQueue.main.async {
                    self.appendLoad()
                }
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
}
