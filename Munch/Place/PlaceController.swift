//
//  PlaceController.swift
//  Munch
//
//  Created by Fuxing Loh on 8/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class PlaceViewController: UIViewController {
    var placeId: String!
    var cards = [PlaceCard]()
    
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
        
        // Register all the cards
        collectionView.register(PlaceShimmerImageBannerCardView.self, forCellWithReuseIdentifier: "PlaceShimmerImageBannerCardView")
        collectionView.register(PlaceShimmerNameCardView.self, forCellWithReuseIdentifier: "PlaceShimmerNameCardView")
        
        // TODO add shimer cards
        // TODO how to differentiate cards
        collectionView.reloadData()
        
        MunchApi.places.cards(id: placeId) { meta, cards in
            if (meta.isOk()) {
                self.cards = cards
                self.collectionView.reloadData()
            } else {
                self.present(meta.createAlert(), animated: true)
            }
        }
    }
    
    // TODO CollectionView functions to render those cards
    // Find correct view
    // Render correct view
    // Assign correct size
}

protocol PlaceCardView {
    
    func render(card: PlaceCard)
    
    var height: CGFloat { get }
}
