//
// Created by Fuxing Loh on 5/3/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import SwiftyJSON

class PlaceExtendedPlaceAwardCard: PlaceCardView {
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = CGSize(width: 160, height: 50)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = UIColor.white
        collectionView.register(PlaceExtendedPlaceAwardCardCell.self, forCellWithReuseIdentifier: "PlaceExtendedPlaceAwardCardCell")
        return collectionView
    }()

    private var awardList = [JSON]()

    override func didLoad(card: PlaceCard) {
        self.awardList = card.data.array ?? []
        self.addSubview(collectionView)

        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        if (!awardList.isEmpty) {
            collectionView.snp.makeConstraints { make in
                make.top.bottom.equalTo(self).inset(topBottom)
                make.height.equalTo(50).priority(999)
                make.left.right.equalTo(self)
            }
        } else {
            let titleView = UILabel()
            titleView.text = "Error Loading Awards"
            titleView.textColor = .primary
            self.addSubview(titleView)

            titleView.snp.makeConstraints { make in
                make.top.bottom.equalTo(self).inset(topBottom)
                make.centerX.equalTo(self)
            }
        }
    }

    override class var cardId: String? {
        return "extended_PlaceAward_20180305"
    }
}

extension PlaceExtendedPlaceAwardCard: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return awardList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceExtendedPlaceAwardCardCell", for: indexPath) as! PlaceExtendedPlaceAwardCardCell
        cell.render(award: awardList[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let award = awardList[indexPath.row]
        if let collectionId = award["collectionId"].string, let userId = award["userId"].string {
            let controller = CollectionPlaceController(userId: userId, collectionId: collectionId)
            self.controller.navigationController?.pushViewController(controller, animated: true)
        }
    }
}

fileprivate class PlaceExtendedPlaceAwardCardCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 3
        imageView.backgroundColor = UIColor(hex: "F0F0F7")
        return imageView
    }()

    private let labelView: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        label.textColor = UIColor(hex: "333333")
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)
        self.addSubview(labelView)

        imageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }

        labelView.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self)
            make.left.right.equalTo(self).inset(8)
        }
    }

    func render(award: JSON) {
        labelView.text = award["awardName"].string
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}