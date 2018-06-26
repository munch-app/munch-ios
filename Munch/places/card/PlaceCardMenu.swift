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

import FirebaseAnalytics

class PlaceHeaderMenuCard: PlaceTitleCardView, SFSafariViewControllerDelegate {
    let webButton: UIButton = {
        let button = UIButton()
        button.setTitle("Web Menu".localized(), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: .medium)

        button.contentEdgeInsets.top = 6
        button.contentEdgeInsets.bottom = 6
        button.contentEdgeInsets.left = 10
        button.contentEdgeInsets.right = 12
        button.imageEdgeInsets.right = -8
        button.setTitleColor(UIColor(hex: "222222"), for: .normal)

        button.setImage(UIImage(named: "RIP-Menu"), for: .normal)
        button.tintColor = UIColor(hex: "222222")

        button.layer.cornerRadius = 3
        button.backgroundColor = UIColor(hex: "F0F0F7")

        button.semanticContentAttribute = .forceRightToLeft
        return button
    }()

    var menuUrl: URL?

    required init(card: PlaceCard, controller: PlaceController) {
        super.init(card: card, controller: controller)
        self.addSubview(webButton)

        webButton.snp.makeConstraints { make in
            make.right.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(titleLabel)
        }

        self.title = "Menu".localized()
        self.webButton.addTarget(self, action: #selector(onWebButton(_:)), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didLoad(card: PlaceCard) {
        if let menuUrl = card.string(name: "menuUrl"), let url = URL(string: menuUrl) {
            self.menuUrl = url
            webButton.isHidden = false
        } else {
            webButton.isHidden = true
        }
    }

    @objc func onWebButton(_ sender: Any) {
        if let url = self.menuUrl {
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            controller.present(safari, animated: true, completion: nil)
        }

        Analytics.logEvent("rip_action", parameters: [
            AnalyticsParameterItemCategory: "click_menu" as NSObject
        ])
    }

    override class var cardId: String? {
        return "header_Menu_20180313"
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
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = UIColor.white
        collectionView.register(PlaceMenuImageCardCell.self, forCellWithReuseIdentifier: "PlaceMenuImageCardCell")
        collectionView.register(PlaceMenuURLCardCell.self, forCellWithReuseIdentifier: "PlaceMenuURLCardCell")
        return collectionView
    }()

    private var menus = [MenuType]()

    override func didLoad(card: PlaceCard) {
        if let anyImages = card["images"] {
            for image in JSON(anyImages).arrayValue {
                menus.append(.image(image))
            }
        }

        self.addSubview(collectionView)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        collectionView.snp.makeConstraints { make in
            make.top.bottom.equalTo(self).inset(topBottom)
            make.height.equalTo(120)
            make.left.right.equalTo(self)
        }
    }

    override class var cardId: String? {
        return "extended_PlaceMenu_20180313"
    }
}

fileprivate enum MenuType {
    case url(String)
    case image(JSON)
}

extension PlaceVendorMenuImageCard: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return menus.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch menus[indexPath.row] {
        case .url:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceMenuURLCardCell", for: indexPath) as! PlaceMenuURLCardCell
        case .image(let json):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceMenuImageCardCell", for: indexPath) as! PlaceMenuImageCardCell
            cell.render(menu: json)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch menus[indexPath.row] {
        case .url(let url):
            if let url = URL(string: url) {
                let safari = SFSafariViewController(url: url)
                safari.delegate = self
                controller.present(safari, animated: true, completion: nil)
            }
        case .image(let json):
            if let imageUrl = json["url"].string, let url = URL(string: imageUrl) {
                let safari = SFSafariViewController(url: url)
                safari.delegate = self
                controller.present(safari, animated: true, completion: nil)
            }
        }
    }
}

fileprivate class PlaceMenuImageCardCell: UICollectionViewCell {
    let imageView: ShimmerImageView = {
        let imageView = ShimmerImageView()
        imageView.layer.cornerRadius = 2
        imageView.backgroundColor = UIColor(hex: "F0F0F7")
        return imageView
    }()

    private let brandLabel: UIButton = {
        let label = UIButton()
        label.titleLabel?.font = UIFont.systemFont(ofSize: 10.0, weight: .regular)
        label.setTitleColor(.white, for: .normal)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.66)
        label.contentEdgeInsets = UIEdgeInsets(topBottom: 3, leftRight: 4)
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 7
        label.isUserInteractionEnabled = false
        return label
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)
        self.addSubview(brandLabel)

        imageView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        brandLabel.snp.makeConstraints { make in
            make.right.equalTo(imageView).inset(5)
            make.bottom.equalTo(imageView).inset(5)
        }
    }

    func render(menu: JSON) {
        let images = menu["thumbnail"].dictionaryObject as? [String: String]
        imageView.render(images: images)
        brandLabel.setTitle(menu["sourceName"].string, for: .normal)
    }

    fileprivate override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = 3
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class PlaceMenuURLCardCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = UIColor(hex: "666666")
        imageView.image = UIImage(named: "RIP-Safari")
        return imageView
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)
        self.layer.cornerRadius = 3
        self.backgroundColor = UIColor(hex: "F0F0F7")

        imageView.snp.makeConstraints { make in
            make.center.equalTo(self)
            make.width.height.equalTo(60)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}