//
//  PlaceController.swift
//  Munch
//
//  Created by Fuxing Loh on 8/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class PlaceViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    var placeId: String!
    var cards = [PlaceCard]()
    
    @IBOutlet weak var cardTableView: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        setBarStyle(whiteBackground: false)
    }
    
    private func setBarStyle(whiteBackground: Bool) {
        if (whiteBackground) {
            navigationController?.navigationBar.barStyle = .default
            navigationItem.leftBarButtonItem!.tintColor = UIColor.black
        } else {
            navigationController?.navigationBar.barStyle = .blackTranslucent
            navigationItem.leftBarButtonItem!.tintColor = UIColor.white
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.cardTableView.delegate = self
        self.cardTableView.dataSource = self
        
        self.cardTableView.rowHeight = UITableViewAutomaticDimension
        self.cardTableView.estimatedRowHeight = 100
        
        // Top: -NavigationBar.height
        // Bottom: BottomBar.height
        self.cardTableView.contentInset = UIEdgeInsets(top: -64, left: 0, bottom: 7, right: 0)
        
        registerCards()
        loadShimmerCards()
        
        MunchApi.places.cards(id: placeId) { meta, cards in
            if (meta.isOk()) {
                self.cards = cards
                self.cardTableView.reloadData()
            } else {
                self.present(meta.createAlert(), animated: true)
            }
        }
    }
}


// CardType and tools
extension PlaceViewController {
    func registerCards() {
        // Register Static Cards
        register(PlaceStaticEmptyCard.self)
        
        // Register Shimmer Cards
        register(PlaceShimmerImageBannerCard.self)
        register(PlaceShimmerNameTagCard.self)
        
        // Register Place Cards
        register(PlaceBasicNameTagCard.self)
        register(PlaceBasicImageBannerCard.self)
        register(PlaceBasicLocationCard.self)
        register(PlaceBasicBusinessHourCard.self)
    }
    
    func loadShimmerCards() {
        cards.append(PlaceCard(cardId: PlaceShimmerImageBannerCard.cardId))
        cards.append(PlaceCard(cardId: PlaceShimmerNameTagCard.cardId))
        cardTableView.reloadData()
    }
    
    private func register(_ cellClass: PlaceCardView.Type) {
        cardTableView.register(cellClass as? Swift.AnyClass, forCellReuseIdentifier: cellClass.cardId)
    }
}

// Card CollectionView
extension PlaceViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let card = cards[indexPath.row]
        
        if let cardView = cardTableView.dequeueReusableCell(withIdentifier: card.cardId) as? PlaceCardView {
            cardView.render(card: card)
            return cardView as! UITableViewCell
        }
        
        // Static Empty CardView
        return cardTableView.dequeueReusableCell(withIdentifier: PlaceStaticEmptyCard.cardId)!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // let placeCard = cards[indexPath.row]
        // TODO: When cards have click features
    }
}

protocol PlaceCardView {
    func render(card: PlaceCard)
    
    var leftRight: CGFloat { get }
    var topBottom: CGFloat { get }
    
    static var cardId: String { get }
}

extension PlaceCardView {
    var leftRight: CGFloat {
        return 24.0
    }
    
    var topBottom: CGFloat {
        return 10.0
    }
}
