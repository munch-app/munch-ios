//
// Created by Fuxing Loh on 2019-01-10.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import SnapKit

import CoreLocation
import RxSwift

class SearchMapController: MHViewController {
    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.showsPointsOfInterest = false
        mapView.showsCompass = false
        mapView.showsUserLocation = true
        mapView.register(MapPlaceAnnotationView.self, forAnnotationViewWithReuseIdentifier: "MapPlaceAnnotationView")
        return mapView
    }()
    private let bottom = SearchMapBottom()
    var cardManager: SearchCardManager

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(bottom)
        // TODO

        self.mapView.delegate = self
    }

    @objc func onShowHeading(_ sender: Any) {
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchMapController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        if let annotation = annotation as? MapPlaceAnnotation {
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "MapPlaceAnnotationView") as! MapPlaceAnnotationView
            return annotationView.render(annotation: annotation)
        }

        return nil
    }
}

class SearchMapBottom: UIView {
    // TODO Scroll Items

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: -2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}