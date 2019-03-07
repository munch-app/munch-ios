//
// Created by Fuxing Loh on 2018-12-01.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import RxSwift

import Toast_Swift
import SwiftRichString

class PlaceHeartButton: UIControl {
    private let imageView = UIImageView()

    init() {
        super.init(frame: .zero)
        self.tintColor = .white
        self.addSubview(imageView)
        self.isHidden = true

        imageView.image = UIImage(named: "RIP-Heart")
        imageView.snp.makeConstraints { maker in
            maker.edges.equalTo(self).inset(8)
        }
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                self.imageView.image = UIImage(named: "RIP-Heart-Filled")
            } else {
                self.imageView.image = UIImage(named: "RIP-Heart")
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PlaceCard: UIView {
    fileprivate let disposeBag = DisposeBag()

    public let heartBtn = PlaceHeartButton()
    private let noImageLabel: UILabel = {
        let label = UILabel(style: .smallBold)
        label.with(text: "No Image Available")
        label.isHidden = true
        return label
    }()
    private let imageView: SizeShimmerImageView = {
        let width = UIScreen.main.bounds.width
        let imageView = SizeShimmerImageView(points: width, height: width)
        imageView.layer.cornerRadius = 3
        return imageView
    }()
    private let overlay = PlaceCardStatusOverlay()
    private let tagView = MunchTagView()
    private let nameLabel = UILabel()
            .with(font: UIFont.systemFont(ofSize: 20, weight: .semibold))
            .with(color: .ba75)
    private let locationLabel = UILabel()
            .with(font: UIFont.systemFont(ofSize: 13, weight: .regular))
            .with(color: .ba75)

    // By setting controller, heartBtn will be available
    var controller: UIViewController! {
        didSet {
            self.heartBtn.isHidden = controller == nil
        }
    }
    var place: Place! {
        didSet {
            self.render(image: self.place)
            self.render(name: self.place)
            self.render(tag: self.place)
            self.render(location: self.place)
            self.overlay.render(place: self.place)
        }
    }

    init() {
        super.init(frame: .zero)
        self.clipsToBounds = true
        self.addSubview(imageView)
        self.addSubview(nameLabel)
        self.addSubview(tagView)
        self.addSubview(locationLabel)
        self.addSubview(heartBtn)
        self.addSubview(noImageLabel)
        self.addSubview(overlay)

        heartBtn.snp.makeConstraints { maker in
            maker.top.right.equalTo(imageView)
        }

        noImageLabel.snp.makeConstraints { maker in
            maker.bottom.right.equalTo(imageView).inset(8)
        }

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
            maker.top.equalTo(nameLabel.snp.bottom).inset(-6)
        }

        locationLabel.snp.makeConstraints { maker in
            maker.bottom.left.right.equalTo(self)
            maker.height.equalTo(19)
            maker.top.equalTo(tagView.snp.bottom).inset(-6)
        }

        overlay.snp.makeConstraints { maker in
            maker.edges.equalTo(self)
        }

        self.addTargets()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PlaceCard {
    func addTargets() {
        self.heartBtn.addTarget(self, action: #selector(onHeart), for: .touchUpInside)
    }

    @objc func onHeart() {
        guard let place = self.place else {
            return
        }
        guard let view = self.controller.view else {
            return
        }

        Authentication.requireAuthentication(controller: controller) { state in
            PlaceSavedDatabase.shared.toggle(placeId: place.placeId).subscribe { (event: SingleEvent<Bool>) in
                let generator = UIImpactFeedbackGenerator()

                switch event {
                case .success(let added):
                    self.heartBtn.isSelected = added
                    generator.impactOccurred()

                    if added {
                        view.makeToast("Added '\(place.name)' to your places.")
                    } else {
                        view.makeToast("Removed '\(place.name)' from your places.")
                    }

                case .error(let error):
                    generator.impactOccurred()
                    self.controller.alert(error: error)
                }
            }.disposed(by: self.disposeBag)
        }
    }
}

extension PlaceCard {
    class func height(width: CGFloat) -> CGFloat {
        let fixed: CGFloat = 28 + 8 + 24 + 6 + 19 + 6
        return ceil((width * 0.6) + fixed)
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
        self.noImageLabel.isHidden = !place.images.isEmpty
        self.imageView.render(image: place.images.get(0))
    }

    fileprivate func render(tag place: Place) {
        self.tagView.removeAll()

        // Render price as first tag
        if let price = place.price?.perPax {
            self.tagView.add(text: "$\(price)", config: PriceViewConfig())
        }

        // Count is Controlled by View
        for tag in place.tags.filter({ $0.type != .Timing }).prefix(3) {
            self.tagView.add(text: tag.name, config: TagViewConfig())
        }

        if self.tagView.isEmpty {
            self.tagView.add(text: Tag.restaurant.name, config: TagViewConfig())
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

class PlaceCardStatusOverlay: UIView {
    private let titleLabel = UILabel(style: .h2)
            .with(color: .white)
            .with(alignment: .center)

    private let messageLabel = UILabel(style: .h5)
            .with(color: .white)
            .with(text: "Place is not available anymore.")
            .with(alignment: .center)

    override required init(frame: CGRect) {
        super.init(frame: frame)

        self.layer.cornerRadius = 3
        self.backgroundColor = .ba50

        let container = ContainerWidget()
        container.add(PaddingWidget(all: 8, view: titleLabel)) { (maker: ConstraintMaker) -> Void in
            maker.left.right.top.equalTo(container)
        }
        container.add(PaddingWidget(bottom: 8, left: 8, right: 8, view: messageLabel)) { (maker: ConstraintMaker) -> Void in
            maker.top.equalTo(titleLabel.snp.bottom).inset(-8)
            maker.left.right.bottom.equalTo(container)
        }

        self.addSubview(container) { (maker: ConstraintMaker) -> Void in
            maker.left.right.equalTo(self)
            maker.centerY.equalTo(self)
        }

        self.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(place: Place) {
        let type = place.status.type

        if case .open = type {
            self.isHidden = true
            return
        }

        self.isHidden = false
        self.titleLabel.text = type.title ?? "Permanently Closed"
    }
}