//
// Created by Fuxing Loh on 17/1/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreLocation

import SnapKit

import FirebaseAnalytics

class PlaceMapController: UIViewController, UIGestureRecognizerDelegate, MKMapViewDelegate, CLLocationManagerDelegate {
    let placeId: String
    let place: Place

    private var headerView: PlaceHeaderView!
    private let bottomView = PlaceMapViewBottom()
    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.showsPointsOfInterest = false
        mapView.showsCompass = false
        mapView.showsUserLocation = true
        mapView.register(LandmarkAnnotationView.self, forAnnotationViewWithReuseIdentifier: "LandmarkAnnotationView")
        return mapView
    }()
    private let headingButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "RIP-Map-Direction"), for: .normal)
        button.tintColor = .black
        button.backgroundColor = .white

        button.layer.cornerRadius = 25
        button.layer.masksToBounds = false
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 4, height: 4)
        button.layer.shadowRadius = 25
        button.layer.shouldRasterize = true
        button.layer.rasterizationScale = UIScreen.main.scale
        return button
    }()
    private let appleButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "RIP-Map-Apple"), for: .normal)
        button.tintColor = .black
        button.backgroundColor = .white

        button.layer.cornerRadius = 25
        button.layer.masksToBounds = false
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 4, height: 4)
        button.layer.shadowRadius = 25
        button.layer.shouldRasterize = true
        button.layer.rasterizationScale = UIScreen.main.scale
        return button
    }()

    private let googleButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "RIP-Map-Google"), for: .normal)
        button.tintColor = .black
        button.backgroundColor = .white

        button.layer.cornerRadius = 25
        button.layer.masksToBounds = false
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 4, height: 4)
        button.layer.shadowRadius = 25
        button.layer.shouldRasterize = true
        button.layer.rasterizationScale = UIScreen.main.scale
        return button
    }()

    private let locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        return manager
    }()

    private var routeLine: MKPolyline!
    private var lastCoordinate: CLLocationCoordinate2D?
    private var placeCoordinate: CLLocationCoordinate2D?

    init(controller: PlaceController) {
        self.placeId = controller.placeId
        self.place = controller.place!
        super.init(nibName: nil, bundle: nil)

        self.headerView = PlaceHeaderView(controller: self, place: controller.place)
        self.headerView.backgroundView.isHidden = true
        self.headerView.shadowView.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        self.mapView.delegate = self
        self.headingButton.addTarget(self, action: #selector(onShowHeading(_:)), for: .touchUpInside)
        self.appleButton.addTarget(self, action: #selector(onOpenMap(_:)), for: .touchUpInside)
        self.googleButton.addTarget(self, action: #selector(onOpenMap(_:)), for: .touchUpInside)

        self.render()

        locationManager.delegate = self
    }

    private func initViews() {
        self.view.addSubview(mapView)
        self.view.addSubview(headerView)
        self.view.addSubview(bottomView)
        self.view.addSubview(headingButton)
        self.view.addSubview(appleButton)
        self.view.addSubview(googleButton)

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }

        mapView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.bottom.equalTo(bottomView.snp.top)
        }

        bottomView.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(self.view)
        }

        headingButton.snp.makeConstraints { make in
            make.right.equalTo(self.view).inset(24)
            make.bottom.equalTo(bottomView.snp.top).inset(-16)
            make.width.height.equalTo(50)
        }

        appleButton.snp.makeConstraints { make in
            make.right.equalTo(self.view).inset(24)
            make.width.height.equalTo(50)
            make.bottom.equalTo(headingButton.snp.top).inset(-12)
        }

        googleButton.snp.makeConstraints { make in
            make.right.equalTo(self.view).inset(24)
            make.width.height.equalTo(50)
            make.bottom.equalTo(appleButton.snp.top).inset(-12)
        }
    }

    private func render() {
        self.bottomView.render(place: place)

        if let latLng = place.location.latLng, let coordinate = CLLocation(latLng: latLng)?.coordinate {
            self.placeCoordinate = coordinate

            // Set center to place location
            var region = MKCoordinateRegion()
            region.center.latitude = coordinate.latitude
            region.center.longitude = coordinate.longitude
            region.span.latitudeDelta = 0.008
            region.span.longitudeDelta = 0.008
            mapView.setRegion(region, animated: true)

            // Add place annotation
            let placeAnnotation = MKPointAnnotation()
            placeAnnotation.coordinate = coordinate
            placeAnnotation.title = place.name
            mapView.addAnnotation(placeAnnotation)
        }

        // Add all the land marks
        if let landmarks = place.location.landmarks {
            for landmark in landmarks {
                mapView.addAnnotation(LandmarkAnnotation(landmark: landmark))
            }
        }

        // Check for Location Services
        if CLLocationManager.locationServicesEnabled() {
            MunchLocation.requestLocation()
            locationManager.startUpdatingLocation()
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(polyline: routeLine)
            renderer.lineWidth = 2
            renderer.strokeColor = UIColor.primary500.withAlphaComponent(0.8)
            return renderer
        }
        return MKOverlayRenderer()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let routeLine = routeLine {
            mapView.remove(routeLine)
            self.routeLine = nil
        }

        if let placeCoordinate = placeCoordinate, let lastCoordinate = locations.last?.coordinate {
            self.routeLine = MKPolyline(coordinates: [placeCoordinate, lastCoordinate], count: 2)
            mapView.add(routeLine)
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        if annotation is LandmarkAnnotation {
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "LandmarkAnnotationView") as! LandmarkAnnotationView
            annotationView.render(annotation: annotation as! LandmarkAnnotation)
            return annotationView
        }

        return nil
    }

    @objc func onOpenMap(_ sender: UIButton) {
        let address = place.location.address?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        if sender == self.appleButton {
            UIApplication.shared.open(URL(string: "http://maps.apple.com/?daddr=\(address)")!)
        } else if sender == self.googleButton {
            if UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!) {
                UIApplication.shared.open(URL(string: "comgooglemaps://?daddr=\(address)")!)
            } else {
                UIApplication.shared.open(URL(string: "https://www.google.com/maps/?daddr=\(address)")!)
            }
        }

        Analytics.logEvent("rip_action", parameters: [
            AnalyticsParameterItemCategory: "click_extended_map_map" as NSObject
        ])
    }

    @objc func onShowHeading(_ sender: Any) {
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        mapView.setUserTrackingMode(.followWithHeading, animated: true)

        Analytics.logEvent("rip_action", parameters: [
            AnalyticsParameterItemCategory: "click_extended_map_heading" as NSObject
        ])
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class LandmarkAnnotation: NSObject, MKAnnotation {
    let landmark: Landmark

    init(landmark: Landmark) {
        self.landmark = landmark
    }

    public var coordinate: CLLocationCoordinate2D {
        if let latLng = landmark.location.latLng, let location = CLLocation(latLng: latLng) {
            return location.coordinate
        }
        return CLLocation().coordinate
    }

    public var title: String? {
        return landmark.name
    }

    public var subtitle: String? {
        return landmark.type.rawValue
    }
}

fileprivate class LandmarkAnnotationView: MKAnnotationView {
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

    func render(annotation: LandmarkAnnotation) {
        self.label.text = annotation.landmark.name

        if annotation.landmark.type == .train {
            self.image = UIImage(named: "RIP-Map-Train")
        } else {
            self.image = UIImage(named: "RIP-Map-Landmark")
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class PlaceMapViewBottom: UIView {
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.initViews()
    }

    private func initViews() {
        self.backgroundColor = .white
        self.addSubview(addressLabel)

        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(self).inset(12)
            make.left.right.equalTo(self).inset(24)
            make.bottom.equalTo(self.safeArea.bottom).inset(8)
        }
    }

    func render(place: Place) {
        self.addressLabel.text = place.location.address
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: -2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}