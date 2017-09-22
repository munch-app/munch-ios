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
    var cells = [Int: PlaceCardView]()
    var cellTypes = [String: PlaceCardView.Type]()
    
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
        self.cardTableView.separatorStyle = .none
        self.cardTableView.delegate = self
        self.cardTableView.dataSource = self
        
        self.cardTableView.rowHeight = UITableViewAutomaticDimension
        self.cardTableView.estimatedRowHeight = 50
        
        // Top: -NavigationBar.height
        // Bottom: BottomBar.height
        self.cardTableView.contentInset = UIEdgeInsets(top: -64, left: 0, bottom: 10, right: 0)
        
        registerCards()
        loadShimmerCards()
        
        MunchApi.places.cards(id: placeId) { meta, cards in
            if (meta.isOk()) {
                self.cards = cards
                self.cells.removeAll()
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
        // Register Shimmer Cards
        register(PlaceShimmerImageBannerCard.self)
        register(PlaceShimmerNameTagCard.self)
        
        // Register Place Cards
        register(PlaceBasicNameTagCard.self)
        register(PlaceBasicImageBannerCard.self)
        register(PlaceBasicLocationCard.self)
        register(PlaceBasicBusinessHourCard.self)
        
        // Register Vendor Cards
        register(PlaceVendorArticleGridCard.self)
    }
    
    func loadShimmerCards() {
        cards.append(PlaceCard(cardId: PlaceShimmerImageBannerCard.cardId!))
        cards.append(PlaceCard(cardId: PlaceShimmerNameTagCard.cardId!))
        cardTableView.reloadData()
    }
    
    private func register(_ cellClass: PlaceCardView.Type) {
        cellTypes[cellClass.cardId!] = cellClass
    }
}

// Card CollectionView
extension PlaceViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let card = cards[indexPath.row]
        
        if let cell = cells[indexPath.row] {
            return cell
        } else {
            let cell = cellTypes[card.cardId]?.init(card: card) ?? PlaceStaticEmptyCard(card: card)
            cells[indexPath.row] = cell
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = cells[indexPath.row] {
            tableView.beginUpdates()
            cell.didTap()
            tableView.endUpdates()
        }
    }
}

class PlaceCardView: UITableViewCell {
    required init(card: PlaceCard) {
        super.init(style: .default, reuseIdentifier: nil)
        self.selectionStyle = .none
        self.didLoad(card: card)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func didLoad(card: PlaceCard) {
        
    }
    
    func didTap() {
        
    }
    
    let leftRight: CGFloat = 24.0
    let topBottom: CGFloat = 10.0
    
    class var cardId: String? { return nil }
}
