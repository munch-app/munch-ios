//
// Created by Fuxing Loh on 20/12/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

import Cosmos
import SnapKit
import SwiftyJSON

class PlaceHeaderMenuCard: PlaceTitleCardView {
    override func didLoad(card: PlaceCard) {
        self.title = "Menu"
    }

    override class var cardId: String? {
        return "header_Menu_20171220"
    }
}

class PlaceVendorMenuImageCard: PlaceCardView, SFSafariViewControllerDelegate {
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = CGSize(width: 120, height: 120)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 18

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.white
        collectionView.register(PlaceMenuImageCardCell.self, forCellWithReuseIdentifier: "PlaceMenuImageCardCell")
        return collectionView
    }()

    private var menus = [JSON]()

    override func didLoad(card: PlaceCard) {
        self.menus = card["menus"].array ?? []
        self.selectionStyle = .default
        self.addSubview(collectionView)

        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        if (!menus.isEmpty) {
            collectionView.snp.makeConstraints { make in
                make.top.bottom.equalTo(self).inset(topBottom)
                make.height.equalTo(120)
                make.left.right.equalTo(self)
            }
        } else {
            let titleView = UILabel()
            titleView.text = "Error Loading Menus"
            titleView.textColor = .primary
            self.addSubview(titleView)

            titleView.snp.makeConstraints { make in
                make.top.bottom.equalTo(self).inset(topBottom)
                make.centerX.equalTo(self)
            }
        }
    }

    override class var cardId: String? {
        return "vendor_MenuImage_20171219"
    }
}

extension PlaceVendorMenuImageCard: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return menus.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let menu = menus[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceMenuImageCardCell", for: indexPath) as! PlaceMenuImageCardCell
        cell.render(menu: menu)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let menu = menus[indexPath.row]

        if let images = menu["images"].dictionaryObject as? [String: String],
           let imageUrl = getLargestImage(images: images),
           let url = URL(string: imageUrl) {
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            controller.present(safari, animated: true, completion: nil)
        }
    }

    private func getLargestImage(images: [String: String]) -> String? {
        return images["original"]
                ?? images["1080x1080"]
                ?? images["640x640"]
                ?? images["320x320"]
                ?? images["150x150"]
                ?? nil
    }
}

fileprivate class PlaceMenuImageCardCell: UICollectionViewCell {
    let imageView: MunchImageView = {
        let imageView = MunchImageView()
        imageView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        return imageView
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    func render(menu: JSON) {
        let images = menu["images"].dictionaryObject as? [String: String]
        imageView.render(images: images)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}