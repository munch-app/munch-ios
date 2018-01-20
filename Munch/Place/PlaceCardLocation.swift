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
            make.height.equalTo(230)
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