//
// Created by Fuxing Loh on 2018-12-01.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class RIPImageBannerCard: RIPCard {
    private let imageGradientView: UIView = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 64)
        gradientLayer.colors = [UIColor.black.withAlphaComponent(0.5).cgColor, UIColor.clear.cgColor]

        let imageGradientView = UIView()
        imageGradientView.layer.insertSublayer(gradientLayer, at: 0)
        imageGradientView.backgroundColor = UIColor.clear
        return imageGradientView
    }()
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.38)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = UIColor.whisper100
        collectionView.register(BannerCell.self, forCellWithReuseIdentifier: "BannerCell")
        return collectionView
    }()

    private let noImageLabel: UILabel = {
        let label = UILabel(style: .smallBold)
        label.with(text: "No Image Available")
        label.isHidden = true
        return label
    }()
    private let moreButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.layer.borderColor = UIColor.ba10.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 3

        button.setTitle("SHOW IMAGES", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = FontStyle.smallBold.font

        button.setImage(UIImage(named: "RIP-Card-Image-More"), for: .normal)
        button.tintColor = UIColor.black
        button.imageEdgeInsets.left = -12
        button.contentEdgeInsets.left = 18
        button.contentEdgeInsets.right = 12

        return button
    }()
    var images = [Image]()

    override func didLoad(data: PlaceData!) {
        self.addSubview(collectionView)
        self.addSubview(imageGradientView)
        self.addSubview(moreButton)
        self.addSubview(noImageLabel)
        self.addTargets()

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        collectionView.snp.makeConstraints { maker in
            maker.height.equalTo(UIScreen.main.bounds.height * 0.33).priority(999)
            maker.edges.equalTo(self).inset(UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0))
        }

        imageGradientView.snp.makeConstraints { maker in
            maker.height.equalTo(64)
            maker.top.left.right.equalTo(self)
        }

        moreButton.snp.makeConstraints { maker in
            maker.right.equalTo(self).inset(24)
            maker.bottom.equalTo(collectionView).inset(16)
            maker.height.equalTo(34)
        }

        noImageLabel.snp.makeConstraints { maker in
            maker.right.bottom.equalTo(collectionView).inset(8)
        }
    }

    override func willDisplay(data: PlaceData!) {
        self.images = data.place.images
        if self.images.isEmpty {
            moreButton.isHidden = true
            noImageLabel.isHidden = false
        }
    }
}

extension RIPImageBannerCard {
    func addTargets() {
        moreButton.addTarget(self, action: #selector(scrollTo(_:)), for: .touchUpInside)
    }

    @objc func scrollTo(_ sender: Any) {
        guard !self.images.isEmpty else {
            return
        }

        MunchAnalytic.logEvent("rip_click_show_images")
        controller.scrollTo(indexPath: [1, 0])
    }
}


extension RIPImageBannerCard: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BannerCell", for: indexPath) as! BannerCell
        cell.render(image: images[indexPath.row])
        return cell
    }
}

fileprivate class BannerCell: UICollectionViewCell {
    let imageView = SizeShimmerImageView(points: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    func render(image: Image) {
        imageView.render(image: image)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}