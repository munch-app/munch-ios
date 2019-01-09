//
// Created by Fuxing Loh on 2018-12-12.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class SearchCardPlaceCollection: UICollectionView {

    var places = [Place]()
    var controller: UIViewController!

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = SearchCardPlaceCollectionCell.size
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 24
        super.init(frame: .zero, collectionViewLayout: layout)

        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.backgroundColor = .clear
        self.register(type: SearchCardPlaceCollectionCell.self)

        self.delegate = self
        self.dataSource = self

        self.snp.makeConstraints { maker in
            maker.height.equalTo(SearchCardPlaceCollectionCell.size.height).priority(.high)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchCardPlaceCollection: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return SearchCardPlaceCollectionCell.size
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return places.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(type: SearchCardPlaceCollectionCell.self, for: indexPath)
        cell.card.place = places[indexPath.row]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let place = places[indexPath.row]
        let controller = RIPController(placeId: place.placeId)
        self.controller.navigationController!.pushViewController(controller, animated: true)
    }
}

class SearchCardPlaceCollectionCell: UICollectionViewCell {
    public static let width = (UIScreen.main.bounds.width - 48) * 0.85
    public static let size = CGSize(width: width, height: PlaceCard.height(width: width))

    fileprivate let card = PlaceCard()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(card)

        card.snp.makeConstraints { maker in
            maker.width.equalTo(SearchCardPlaceCollectionCell.width)
            maker.edges.equalTo(self).priority(.high)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}