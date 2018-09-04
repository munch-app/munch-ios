//
// Created by Fuxing Loh on 20/1/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import MapKit

import SwiftyJSON
import SnapKit
import SwiftRichString
import SafariServices

class PlaceHeaderLocationCard: PlaceTitleCardView {
    override func didLoad(card: PlaceCard) {
        self.title = "Location".localized()
        self.moreButton.isHidden = true
    }

    override func didTap() {
        self.controller.apply(click: .map)
    }

    override class var cardId: String? {
        return "header_Location_20171112"
    }
}

class PlaceBasicLocationCard: PlaceCardView {
    private let mapView = UIImageView()
    private let pinImageView = UIImageView()
    private let addressLabel = AddressLabel()

    override func didLoad(card: PlaceCard) {
        self.addSubview(mapView)
        self.addSubview(pinImageView)
        self.addSubview(addressLabel)

        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(self).inset(4).priority(999)
            make.left.right.equalTo(self).inset(leftRight)
        }

        pinImageView.snp.makeConstraints { make in
            make.center.equalTo(mapView)
        }

        mapView.snp.makeConstraints { make in
            make.top.equalTo(addressLabel.snp.bottom).inset(-topBottom*2).priority(999)
            make.bottom.equalTo(self).inset(topBottom)
            make.left.right.equalTo(self).inset(leftRight)
            make.height.equalTo(230).priority(999)
        }

        mapView.clipsToBounds = true
        mapView.layer.cornerRadius = 4

        if let location = card.decode(name: "location", Location.self) {
            render(location: location)
        }
    }

    override func didTap() {
        self.controller.apply(click: .map)
    }

    private func render(location: Location) {
        if let latLng = location.latLng, let coordinate = CLLocation(latLng: latLng)?.coordinate {
            var region = MKCoordinateRegion()
            region.center.latitude = coordinate.latitude
            region.center.longitude = coordinate.longitude
            region.span.latitudeDelta = 0.004
            region.span.longitudeDelta = 0.004

            let options = MKMapSnapshotOptions()
            options.showsPointsOfInterest = false
            options.region = region
            options.size = CGSize(width: UIScreen.main.bounds.width, height: 230)

            MKMapSnapshotter(options: options).start { snapshot, error in
                self.mapView.image = snapshot?.image
                self.pinImageView.image = UIImage(named: "RIP-PlaceMarker")
            }
        }

        self.addressLabel.render(location: location)
    }

    override class var cardId: String? {
        return "basic_Location_20180613"
    }
}

class PlaceBasicAddressCard: PlaceCardView {
    private let addressLabel = AddressLabel()

    override func didLoad(card: PlaceCard) {
        self.selectionStyle = .default
        self.addSubview(addressLabel)

        if let location = card.decode(name: "location", Location.self) {
            addressLabel.render(location: location)
        }

        addressLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(self).inset(topBottom)
            make.left.right.equalTo(self).inset(leftRight)
        }
    }

    override func didTap() {
        self.controller.apply(click: .map)
    }

    override class var cardId: String? {
        return "basic_Address_20180613"
    }
}

class AddressLabel: SRCopyableView {
    let lineOneLabel = UILabel()
    let lineTwoLabel = UILabel()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        lineOneLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .regular)
        lineOneLabel.numberOfLines = 0
        self.addSubview(lineOneLabel)

        lineTwoLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .regular)
        lineTwoLabel.numberOfLines = 1
        self.addSubview(lineTwoLabel)

        lineOneLabel.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.left.right.equalTo(self)
        }

        lineTwoLabel.snp.makeConstraints { make in
            make.top.equalTo(lineOneLabel.snp.bottom)
            make.left.right.equalTo(self)
            make.bottom.equalTo(self)
        }
    }

    override var copyableText: String? {
        return self.lineOneLabel.text
    }

    func render(location: Location) {
        render(lineOne: location.address)
        render(lineTwo: location.latLng, landmarks: location.landmarks)
    }

    func render(place: Place) {
        render(lineOne: place.location.address)
        render(lineTwo: place.location.latLng, landmarks: place.location.landmarks)
    }

    private func render(lineOne address: String?) {
        lineOneLabel.text = address
    }

    private func render(lineTwo latLng: String?, landmarks: [Landmark]?) {
        let attributedText = NSMutableAttributedString()

        if let latLng = latLng, MunchLocation.isEnabled {
            if let distance = MunchLocation.distance(asMetric: latLng) {
                attributedText.append(NSAttributedString(string: distance))
            }

            if let landmarks = landmarks {
                for landmark in landmarks {
                    if let min = MunchLocation.distance(asDuration: landmark.location.latLng, toLatLng: latLng) {
                        attributedText.append(NSAttributedString(string: " • \(min) from "))
                        attributedText.append(NSAttributedString(string: landmark.name))
                        break
                    }
                }
            }
        }

        lineTwoLabel.attributedText = attributedText
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}