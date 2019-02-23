//
// Created by Fuxing Loh on 2018-12-01.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import SafariServices

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
        collectionView.register(type: BannerCell.self)
        return collectionView
    }()
    private let creditLabel = UILabel(style: .small)
            .with(color: .white)
            .with(numberOfLines: 2)
    private let creditControl = UIControl()
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
    var image: CreditedImage? {
        return self.controller.focusedImage
    }

    override func didLoad(data: PlaceData!) {
        self.addSubview(collectionView)
        self.addSubview(imageGradientView)

        self.addSubview(creditLabel)
        self.addSubview(creditControl)

        self.addSubview(moreButton)

        self.addTargets()

        self.collectionView.dataSource = self
        self.collectionView.delegate = self
    }

    override func willDisplay(data: PlaceData!) {
        if image == nil {
            moreButton.isHidden = true
            imageGradientView.isHidden = true
            collectionView.isHidden = true
        }

        collectionView.snp.makeConstraints { maker in
            if let multiplier = self.image?.sizes.max?.heightMultiplier {
                maker.height.equalTo(UIScreen.main.bounds.width * CGFloat(multiplier)).priority(999)
            } else {
                maker.height.equalTo(self.safeAreaInsets.top + 36).priority(999)
            }
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

        if let name = self.image?.name {
            creditLabel.text = "Image by:\n\(name)"
        }
        creditLabel.snp.makeConstraints { maker in
            maker.left.bottom.equalTo(self).inset(24)
        }

        creditControl.snp.makeConstraints { maker in
            maker.left.bottom.equalTo(self)
            maker.right.top.equalTo(creditLabel).inset(-24)
        }
    }
}

extension RIPImageBannerCard: SFSafariViewControllerDelegate {
    func addTargets() {
        moreButton.addTarget(self, action: #selector(scrollTo(_:)), for: .touchUpInside)
        creditControl.addTarget(self, action: #selector(onCredit), for: .touchUpInside)
    }

    @objc func scrollTo(_ sender: Any) {
        guard self.image != nil else {
            return
        }

        MunchAnalytic.logEvent("rip_click_show_images")
        controller.scrollTo(indexPath: [1, 0])
    }

    @objc func onCredit() {
        guard let name = self.image?.name, let link = self.image?.link, let url = URL(string: link) else {
            return
        }

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "More from \(name)", style: .default) { action in
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            self.controller.present(safari, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.controller.present(alert, animated: true)
    }
}

extension RIPImageBannerCard: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return image != nil ? 1 : 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(type: BannerCell.self, for: indexPath)
        cell.render(sizes: image!.sizes)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let multiplier = image?.sizes.max?.heightMultiplier ?? 1

        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: width * CGFloat(multiplier))
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

    func render(sizes: [Image.Size]) {
        imageView.render(sizes: sizes)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}