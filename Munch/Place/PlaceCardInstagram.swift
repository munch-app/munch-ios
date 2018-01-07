//
// Created by Fuxing Loh on 9/12/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

import SnapKit
import SwiftyJSON

class PlaceHeaderInstagramCard: PlaceTitleCardView {
    override func didLoad(card: PlaceCard) {
        self.title = "Instagram"
    }

    override class var cardId: String? {
        return "header_Instagram_20171208"
    }
}

class PlaceVendorInstagramCard: PlaceCardView {
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = CGSize(width: 150, height: 150)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 18

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = UIColor.white
        collectionView.register(PlaceVendorInstagramCardCell.self, forCellWithReuseIdentifier: "PlaceVendorInstagramCardCell")
        return collectionView
    }()

    private var medias = [InstagramMedia]()

    override func didLoad(card: PlaceCard) {
        self.medias = card.data.map({ InstagramMedia(json: $0.1) })
        self.addSubview(collectionView)

        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        if (!medias.isEmpty) {
            collectionView.snp.makeConstraints { make in
                make.top.bottom.equalTo(self).inset(topBottom)
                make.height.equalTo(150)
                make.left.right.equalTo(self)
            }
        } else {
            let titleView = UILabel()
            titleView.text = "Error Loading Instagram Images"
            titleView.textColor = .primary
            self.addSubview(titleView)

            titleView.snp.makeConstraints { make in
                make.top.bottom.equalTo(self).inset(topBottom)
                make.centerX.equalTo(self)
            }
        }
    }

    override class var cardId: String? {
        return "vendor_InstagramMedia_20171204"
    }
}

extension PlaceVendorInstagramCard: UICollectionViewDataSource, UICollectionViewDelegate, SFSafariViewControllerDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return medias.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceVendorInstagramCardCell", for: indexPath) as! PlaceVendorInstagramCardCell
        cell.render(media: medias[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let mediaId = medias[indexPath.row].mediaId, let url = URL(string: "instagram://media?id=\(mediaId)") {
            if (UIApplication.shared.canOpenURL(url)) {
                UIApplication.shared.open(url)
            }
        }
    }
}

fileprivate class PlaceVendorInstagramCardCell: UICollectionViewCell {
    private let mediaImageView: ShimmerImageView = {
        let imageView = ShimmerImageView()
        imageView.layer.cornerRadius = 2
        return imageView
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(mediaImageView)

        mediaImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }

    func render(media: InstagramMedia) {
        mediaImageView.render(images: media.images)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}