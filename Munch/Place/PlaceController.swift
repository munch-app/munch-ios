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
    var cardTypes = [String: PlaceCardView.Type]()
    
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
        self.cardTableView.estimatedRowHeight = 44
        
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
    
    private func loadShimmerCards() {
        cards.append(PlaceCard(id: ShimmerImageBannerCardView.id))
        cards.append(PlaceCard(id: ShimmerNameCardView.id))
        cardTableView.reloadData()
    }
}


// CardType and tools
extension PlaceViewController {
    func registerCards() {
        // Register Static Cards
        register(StaticEmptyCardView.self)
        
        // Register Shimmer Cards
        register(ShimmerImageBannerCardView.self)
        register(ShimmerNameCardView.self)
        
        // Register Place Cards
        register(BasicNameCardView.self)
        register(BasicImageBannerCardView.self)
    }
    
    private func register(_ cellClass: PlaceCardView.Type) {
        cardTableView.register(cellClass as? Swift.AnyClass, forCellReuseIdentifier: cellClass.id)
    }
}

// Card CollectionView
extension PlaceViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let placeCard = cards[indexPath.row]
        
        if let cardView = cardTableView.dequeueReusableCell(withIdentifier: placeCard.id) as? PlaceCardView {
            cardView.render(card: placeCard)
            return cardView as! UITableViewCell
        }
        
        // Static Empty CardView
        return cardTableView.dequeueReusableCell(withIdentifier: StaticEmptyCardView.id)!
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
    
    static var id: String { get }
}

extension PlaceCardView {
    var leftRight: CGFloat {
        return 24.0
    }
    
    var topBottom: CGFloat {
        return 10.0
    }
}

class StaticEmptyCardView: UITableViewCell, PlaceCardView {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.black
        self.snp.makeConstraints { make in
            make.height.equalTo(0)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: PlaceCard) {
    }
    
    static var id: String {
        return "static_PlaceStaticEmptyCardView"
    }
}
