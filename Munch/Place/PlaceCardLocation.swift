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
import TTGTagCollectionView

import FirebaseAnalytics

class PlaceHeaderLocationCard: PlaceTitleCardView {
    override func didLoad(card: PlaceCard) {
        self.title = "Map"
        self.moreButton.isHidden = false
    }

    override func didTap() {
        if let place = self.controller.place {
            let controller = PlaceMapViewController.init(place: place)
            self.controller.navigationController?.pushViewController(controller, animated: true)
        }

        Analytics.logEvent("rip_action", parameters: [
            AnalyticsParameterItemCategory: "click_map" as NSObject
        ])
    }

    override class var cardId: String? {
        return "header_Location_20171112"
    }
}

class PlaceBasicLocationCard: PlaceCardView {
    private let mapView = UIImageView()
    private let pinImageView = UIImageView()

    override func didLoad(card: PlaceCard) {
        self.addSubview(mapView)
        self.addSubview(pinImageView)

        mapView.snp.makeConstraints { make in
            make.top.equalTo(self).inset(4)
            make.bottom.equalTo(self)
            make.left.right.equalTo(self)
            make.height.equalTo(230).priority(999)
        }

        pinImageView.snp.makeConstraints { make in
            make.center.equalTo(mapView)
        }

        render(location: card)
    }

    override func didTap() {
        if let place = self.controller.place {
            let controller = PlaceMapViewController.init(place: place)
            self.controller.navigationController?.pushViewController(controller, animated: true)
        }
    }

    private func render(location card: PlaceCard) {
        if let coordinate = CLLocation(latLng: card["latLng"].stringValue)?.coordinate {
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
    }

    override class var cardId: String? {
        return "basic_Location_20171112"
    }
}

class PlaceBasicAddressCard: PlaceCardView {
    private let addressLabel = AddressLabel()
    private var address: String?

    override func didLoad(card: PlaceCard) {
        self.selectionStyle = .default
        self.addSubview(addressLabel)
        self.address = card["address"].string

        addressLabel.render(card: card)
        addressLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(self).inset(topBottom)
            make.left.right.equalTo(self).inset(leftRight)
        }
    }

    override func didTap() {
        if let place = self.controller.place {
            let controller = PlaceMapViewController.init(place: place)
            self.controller.navigationController?.pushViewController(controller, animated: true)
        }

        Analytics.logEvent("rip_action", parameters: [
            AnalyticsParameterItemCategory: "click_address" as NSObject
        ])
    }

    override class var cardId: String? {
        return "basic_Address_20170924"
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

    func render(card: PlaceCard) {
        render(lineOne: card["address"].string)
        let landmarks = card["landmarks"].compactMap({ Place.Location.Landmark(json: $0.1) })
        render(lineTwo: card["latLng"].string, landmarks: landmarks)
    }

    func render(place: Place) {
        render(lineOne: place.location.address)
        render(lineTwo: place.location.latLng, landmarks: place.location.landmarks)
    }

    private func render(lineOne address: String?) {
        lineOneLabel.text = address
    }

    private func render(lineTwo latLng: String?, landmarks: [Place.Location.Landmark]?) {
        let attributedText = NSMutableAttributedString()

        if let latLng = latLng, MunchLocation.isEnabled {
            if let distance = MunchLocation.distance(asMetric: latLng) {
                attributedText.append(NSAttributedString(string: distance))
            }

            if let landmarks = landmarks {
                for landmark in landmarks {
                    if let name = landmark.name, let min = MunchLocation.distance(asDuration: landmark.latLng, toLatLng: latLng) {
                        attributedText.append(NSAttributedString(string: " • \(min) from "))
                        attributedText.append(NSAttributedString(string: name))
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