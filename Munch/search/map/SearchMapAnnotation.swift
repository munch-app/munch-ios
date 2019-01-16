//
// Created by Fuxing Loh on 2019-01-10.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import SnapKit

class MapPlaceAnnotation: NSObject, MKAnnotation {
    let place: Place

    init(place: Place) {
        self.place = place
    }

    public var coordinate: CLLocationCoordinate2D {
        if let latLng = place.location.latLng, let location = CLLocation(latLng: latLng) {
            return location.coordinate
        }
        return CLLocation().coordinate
    }

    public var title: String? {
        return place.name
    }

    public var subtitle: String? {
        return ""
    }
}

class MapPlaceAnnotationView: MKAnnotationView {
    fileprivate let label: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        return label
    }()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.canShowCallout = false
        self.addSubview(label)

        label.snp.makeConstraints { make in
            make.top.equalTo(self.snp.bottom).inset(-1)
            make.centerX.equalTo(self)
        }
    }

    func render(annotation: MapPlaceAnnotation) -> MapPlaceAnnotationView{
        self.label.text = annotation.place.name
        self.image = UIImage(named: "RIP-Map-Landmark")
        return self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
