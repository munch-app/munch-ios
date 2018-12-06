//
// Created by Fuxing Loh on 2018-12-01.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import Toast_Swift
import SwiftRichString

class PlaceCard: UIView {
    private let imageView: SizeShimmerImageView = {
        let width = UIScreen.main.bounds.width
        let imageView = SizeShimmerImageView(points: width, height: width)
        imageView.layer.cornerRadius = 3
        return imageView
    }()
    private let nameLabel: UILabel = {
        let nameLabel = UILabel()
                .with(font: UIFont.systemFont(ofSize: 20, weight: .semibold))
                .with(color: .ba75)
        return nameLabel
    }()
    private let tagView: MunchTagView = {
        let tagView = MunchTagView()
        return tagView
    }()
    private let locationLabel: UILabel = {
        let locationLabel = UILabel()
                .with(font: UIFont.systemFont(ofSize: 13, weight: .regular))
                .with(color: .ba75)
        return locationLabel
    }()

    var controller: UIViewController!
    var place: Place! {
        didSet {
            self.render(image: self.place)
            self.render(name: self.place)
            self.render(tag: self.place)
            self.render(location: self.place)
        }
    }

    init() {
        super.init(frame: .zero)
        self.addSubview(imageView)
        self.addSubview(nameLabel)
        self.addSubview(tagView)
        self.addSubview(locationLabel)

        self.isUserInteractionEnabled = false

        imageView.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(self)
            maker.height.equalTo(imageView.snp.width).multipliedBy(0.6)
        }

        nameLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.height.equalTo(28)
            maker.top.equalTo(imageView.snp.bottom).inset(-8)
        }

        tagView.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.height.equalTo(24)
            maker.top.equalTo(nameLabel.snp.bottom).inset(-4)
        }

        locationLabel.snp.makeConstraints { maker in
            maker.bottom.left.right.equalTo(self)
            maker.height.equalTo(19)
            maker.top.equalTo(tagView.snp.bottom).inset(-4)

        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PlaceCard {
    static let period = " • ".set(style: Style {
        $0.font = UIFont.systemFont(ofSize: 15, weight: .ultraLight)
    })
    static let closing = "Closing Soon".set(style: Style {
        $0.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        $0.color = UIColor.close
    })
    static let closed = "Closed Now".set(style: Style {
        $0.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        $0.color = UIColor.close
    })
    static let opening = "Opening Soon".set(style: Style {
        $0.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        $0.color = UIColor.open
    })
    static let open = "Open Now".set(style: Style {
        $0.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        $0.color = UIColor.open
    })

    fileprivate func render(name place: Place) {
        self.nameLabel.text = place.name
    }

    fileprivate func render(image place: Place) {
        self.imageView.render(image: place.images.get(0))
    }

    fileprivate func render(tag place: Place) {
        self.tagView.removeAll()

        // Render price as first tag
        if let price = place.price?.perPax {
            self.tagView.add(text: "$\(price)", config: PriceViewConfig())
        }

        // Count is Controlled by View
        for tag in place.tags.prefix(3) {
            self.tagView.add(text: tag.name, config: TagViewConfig())
        }
    }

    fileprivate func render(location place: Place) {
        let line = NSMutableAttributedString()

        if let latLng = place.location.latLng, let distance = MunchLocation.distance(asMetric: latLng) {
            line.append(AttributedString(string: "\(distance) - "))
        }

        if let neighbourhood = place.location.neighbourhood {
            line.append(AttributedString(string: neighbourhood))
        } else {
            line.append(AttributedString(string: "Singapore"))
        }

        // Open Now
        switch place.hours.isOpen() {
        case .opening:
            line.append(PlaceCard.period)
            line.append(PlaceCard.opening)
        case .open:
            line.append(PlaceCard.period)
            line.append(PlaceCard.open)
        case .closed:
            line.append(PlaceCard.period)
            line.append(PlaceCard.closed)
        case .closing:
            line.append(PlaceCard.period)
            line.append(PlaceCard.closing)
        case .none:
            break
        }
        self.locationLabel.attributedText = line
    }
}

class PlaceAddButton: UIButton {
    private let toastStyle: ToastStyle = {
        var style = ToastStyle()
        style.backgroundColor = UIColor.whisper100
        style.cornerRadius = 5
        style.imageSize = CGSize(width: 20, height: 20)
        style.fadeDuration = 6.0
        style.messageColor = UIColor.black.withAlphaComponent(0.85)
        style.messageFont = UIFont.systemFont(ofSize: 15, weight: .regular)
        style.messageNumberOfLines = 2
        style.messageAlignment = .left

        return style
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.setImage(UIImage(named: "RIP-Add"), for: .normal)
        self.tintColor = .white

        self.addTarget(self, action: #selector(onButton(_:)), for: .touchUpInside)
    }

    var controller: UIViewController?
    var place: Place?

    @objc func onButton(_ button: Any) {
        guard let controller = self.controller, let place = self.place else {
            return
        }

        Authentication.requireAuthentication(controller: controller) { state in
            switch state {
            case .loggedIn:
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                let controller = CollectionAddPlaceController(place: place) { action in
                    switch action {
                    case .add(let collection):
                        if let placeController = self.controller as? RIPController {
                            placeController.apply(click: .addedToCollection)
                        }
                        self.controller?.makeToast("Added to \(collection.name)", image: .checkmark)

                    case .remove(let collection):
                        self.controller?.makeToast("Removed from \(collection.name)", image: .checkmark)

                    default:
                        return
                    }

                }
                self.controller?.present(controller, animated: true)
            default:
                return
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate struct TagViewConfig: MunchTagViewConfig {
    let font = UIFont.systemFont(ofSize: 13.0, weight: .medium)
    let textColor = UIColor.ba85
    let backgroundColor = UIColor.whisper100

    let extra = CGSize(width: 16, height: 9)
}

fileprivate struct PriceViewConfig: MunchTagViewConfig {
    let font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
    let textColor = UIColor.ba85
    let backgroundColor = UIColor.peach100

    let extra = CGSize(width: 16, height: 9)
}