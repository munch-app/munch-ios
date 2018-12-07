//
// Created by Fuxing Loh on 2018-12-07.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class RIPAwardCard: RIPCard {
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = CGSize(width: 168, height: 50)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = UIColor.white
        return collectionView
    }()

    private var items = [UserPlaceCollection.Item]()

    override func didLoad(data: PlaceData!) {
        self.items = data.awards

        self.addSubview(collectionView)
        self.registerCells()

        collectionView.snp.makeConstraints { make in
            make.top.bottom.equalTo(self).inset(12)
            make.left.right.equalTo(self)
            make.height.equalTo(50).priority(999)
        }
    }

    override class func isAvailable(data: PlaceData) -> Bool {
        return !data.awards.isEmpty
    }
}

extension RIPAwardCard: UICollectionViewDataSource, UICollectionViewDelegate {
    func registerCells() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        self.collectionView.register(type: RIPAwardCardCell.self)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(type: RIPAwardCardCell.self, for: indexPath)
        cell.render(item: items[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // TODO
    }
}

fileprivate class RIPAwardCardCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 3
        imageView.backgroundColor = .whisper100
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

    func render(item: UserPlaceCollection.Item) {
        labelView.text = item.award?.name
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}