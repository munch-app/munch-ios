//
// Created by Fuxing Loh on 17/1/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import MapKit
import CoreLocation

class PlaceMapViewController: UIViewController, UIGestureRecognizerDelegate, MKMapViewDelegate {
    let placeId: String
    let place: Place

    private let headerView = PlaceMapViewHeader()
    private let mapView = MKMapView()

    private var routeLine: MKPolyline!

    init(place: Place) {
        self.placeId = place.id!
        self.place = place
        super.init(nibName: nil, bundle: nil)
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
        self.headerView.backButton.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)
        self.headerView.mapButton.addTarget(self, action: #selector(onOpenMap(_:)), for: .touchUpInside)

        self.render()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onShowHeading(self.headerView.mapButton)
    }

    private func initViews() {
        self.view.addSubview(mapView)
        self.view.addSubview(headerView)

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }

        mapView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    }

    private func render() {
        if let latLng = place.location.latLng, let coordinate = CLLocation(latLng: latLng)?.coordinate {
            var region = MKCoordinateRegion()
            region.center.latitude = coordinate.latitude
            region.center.longitude = coordinate.longitude
            region.span.latitudeDelta = 0.006
            region.span.longitudeDelta = 0.006
            mapView.setRegion(region, animated: true)

            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = place.name
            mapView.addAnnotation(annotation)

            if let userCoordinate = MunchLocation.lastCoordinate {
                self.routeLine = MKPolyline.init(coordinates: [coordinate, userCoordinate], count: 2)
                mapView.setVisibleMapRect(routeLine.boundingMapRect, animated: false)
                mapView.add(routeLine)
            }
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer.init(polyline: routeLine)
            renderer.lineWidth = 2
            renderer.strokeColor = UIColor.primary500.withAlphaComponent(0.75)
            return renderer
        }
        return MKOverlayRenderer.init()
    }

    @objc func onOpenMap(_ sender: Any) {
        if let address = place.location.address?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            if UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!) {
                alert.addAction(UIAlertAction(title: "Google Maps", style: UIAlertActionStyle.default) { alert in
                    UIApplication.shared.open(URL(string: "comgooglemaps://?daddr=\(address)")!)
                })
            } else {
                alert.addAction(UIAlertAction(title: "Google Maps", style: UIAlertActionStyle.default) { alert in
                    UIApplication.shared.open(URL(string: "https://www.google.com/maps/?daddr=\(address)")!)
                })
            }

            alert.addAction(UIAlertAction(title: "Apple Maps", style: UIAlertActionStyle.default) { alert in
                UIApplication.shared.open(URL(string: "http://maps.apple.com/?daddr=\(address)")!)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alert, animated: true)
        }
    }

    @objc func onShowHeading(_ sender: Any) {
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
    }

    @objc func onBackButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class PlaceMapViewHeader: UIView {
    fileprivate let backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "NavigationBar-Back"), for: .normal)
        button.tintColor = .black
        button.imageEdgeInsets.left = 18
        button.contentHorizontalAlignment = .left
        return button
    }()

    fileprivate let mapButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "RIP-Map"), for: .normal)
        button.tintColor = .black
        button.imageEdgeInsets.right = 20
        button.contentHorizontalAlignment = .right
        return button
    }()

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.initViews()
    }

    private func initViews() {
        self.addSubview(backButton)
        self.addSubview(mapButton)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.bottom.equalTo(self)
            make.left.equalTo(self)

            make.width.equalTo(64)
            make.height.equalTo(44)
        }

        mapButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.bottom.equalTo(self)
            make.right.equalTo(self)

            make.width.equalTo(64)
            make.height.equalTo(44)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
