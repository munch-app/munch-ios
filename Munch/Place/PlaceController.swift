//
//  PlaceController.swift
//  Munch
//
//  Created by Fuxing Loh on 8/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class PlaceViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var placeId: String!
    var cards = [PlaceCard]()
    var cardTypes = [String: PlaceCardView.Type]()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        // Top: -NavBar
        // Bottom: BottomBar
        layout.sectionInset = UIEdgeInsets(top: -64, left: 0, bottom: 7, right: 0)
        
        registerCards()
        loadShimmerCards()
        
//        MunchApi.places.cards(id: placeId) { meta, cards in
//            if (meta.isOk()) {
//                self.cards = cards
//                self.collectionView.reloadData()
//            } else {
//                self.present(meta.createAlert(), animated: true)
//            }
//        }
    }
    
    private func loadShimmerCards() {
        cards.append(PlaceCard(id: PlaceShimmerImageBannerCardView.id))
        cards.append(PlaceCard(id: PlaceShimmerNameCardView.id))
        collectionView.reloadData()
    }
}


// CardType and tools
extension PlaceViewController {
    func registerCards() {
        // Register Shimmer Cards
        register(PlaceShimmerImageBannerCardView.self, forCellWithReuseIdentifier: "PlaceShimmerImageBannerCardView")
        register(PlaceShimmerNameCardView.self, forCellWithReuseIdentifier: "PlaceShimmerNameCardView")
    }
    
    func findCardType(card: PlaceCard) -> (String, PlaceCardView.Type)? {
        for type in cardTypes {
            if (type.value.id == card.id) {
                return type
            }
        }
        return nil
    }
    
    private func register(_ cellClass: PlaceCardView.Type, forCellWithReuseIdentifier identifier: String) {
        collectionView.register(cellClass as? Swift.AnyClass, forCellWithReuseIdentifier: identifier)
        cardTypes[identifier] = cellClass
    }
}

// Card CollectionView
extension PlaceViewController {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let placeCard = cards[indexPath.row]
        if let (_, type) = findCardType(card: placeCard) {
            return type.size
        }
        return CGSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let placeCard = cards[indexPath.row]
        
        if let (identifier, _) = findCardType(card: placeCard) {
            let cardView = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! PlaceCardView
            cardView.render(card: placeCard)
            return cardView as! UICollectionViewCell
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // let placeCard = cards[indexPath.row]
        // TODO: When cards have click features
    }
}

protocol PlaceCardView {
    func render(card: PlaceCard)
    
    static var id: String { get }
    
    static var height: CGFloat { get }
    
    static var size: CGSize { get }
}

extension PlaceCardView {
    static var size: CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: self.height)
    }
}
