//
// Created by Fuxing Loh on 2018-12-06.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import SafariServices

import NVActivityIndicatorView

class RIPGalleryHeaderCard: RIPCard {
    private let label = UILabel(style: .h2)

    override func didLoad(data: PlaceData!) {
        self.addSubview(label)

        label.with(text: "\(data.place.name) Images")
        label.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(12)
            maker.bottom.equalTo(self).inset(24)
        }

        self.layoutIfNeeded()
    }

    override class func isAvailable(data: PlaceData) -> Bool {
        return !data.images.isEmpty
    }
}

class RIPGalleryImageCard: UICollectionViewCell {
    private let imageView: SizeImageView = {
        let width = (UIScreen.main.bounds.width - 24 - 24 - 16) / 2
        let imageView = SizeShimmerImageView(points: width, height: 1)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 3
        return imageView
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)

        self.layer.masksToBounds = true
        self.layer.cornerRadius = 3

        imageView.snp.makeConstraints { maker in
            maker.edges.equalTo(self).priority(999)
        }
    }

    @discardableResult
    func render(with image: PlaceImage) -> RIPGalleryImageCard {
        imageView.render(sizes: image.sizes)
        return self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class func size(image: PlaceImage) -> CGSize {
        if let size = image.sizes.max {
            return CGSize(width: size.width, height: size.height)
        }
        return CGSize(width: 10000, height: 10000)
    }
}

class RIPGalleryFooterCard: RIPCard, SFSafariViewControllerDelegate {
    let indicator: NVActivityIndicatorView = {
        let indicator = NVActivityIndicatorView(frame: .zero, type: .ballBeat, color: .secondary500, padding: 0)
        return indicator
    }()

    let connect = RIPGalleryConnectCard()

    var loading: Bool = true {
        didSet {
            if loading {
                indicator.startAnimating()
                connect.isHidden = true
            } else {
                indicator.stopAnimating()
                connect.isHidden = false
            }
        }
    }

    override func didLoad(data: PlaceData!) {
        self.addSubview(indicator)
        self.addSubview(connect)

        connect.button.addTarget(self, action: #selector(onConnect), for: .touchUpInside)

        self.loading = true

        indicator.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(self).inset(24)
            maker.height.equalTo(36).priority(.high)
        }

        connect.snp.makeConstraints { maker in
            maker.top.equalTo(self).inset(36)
            maker.left.right.bottom.equalTo(self).inset(24)
        }
    }

    @objc func onConnect() {
        let safari = SFSafariViewController(url: URL(string: "https://partner.munch.app/instagram")!)
        safari.delegate = self
        controller.present(safari, animated: true, completion: nil)
    }
}

class RIPGalleryConnectCard: UIView {
    let label = UILabel(style: .h5)
            .with(alignment: .center)
            .with(text: "Join as Partner, show your images.")

    let button: MunchButton = {
        let button = MunchButton(style: .secondaryOutline)
        button.with(text: "Connect")
        return button
    }()

    init() {
        super.init(frame: .zero)
        self.addSubview(label)
        self.addSubview(button)

        self.layer.cornerRadius = 3
        self.backgroundColor = .saltpan100

        label.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(self).inset(24)
        }

        button.snp.makeConstraints { maker in
            maker.top.equalTo(label.snp.bottom).inset(-24)
            maker.bottom.equalTo(self).inset(24)
            maker.centerX.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}