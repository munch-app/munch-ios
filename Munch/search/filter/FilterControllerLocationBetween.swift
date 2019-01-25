//
// Created by Fuxing Loh on 2018-12-04.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import SnapKit

import Moya
import RxSwift
import RxCocoa

import NVActivityIndicatorView

class FilterLocationBetweenController: UIViewController {
    private let onDismiss: ((SearchQuery?) -> Void)
    private let searchQuery: SearchQuery

    private var points = [SearchQuery.Filter.Location.Point]()

    private let manager: FilterManager
    private let disposeBag = DisposeBag()

    fileprivate let headerView = FilterLocationBetweenHeaderView()
    fileprivate let bottomView = FilterLocationBetweenBottomView()

    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.showsPointsOfInterest = false
        mapView.showsCompass = false
        mapView.isUserInteractionEnabled = false
        mapView.register(BetweenAnnotationView.self, forAnnotationViewWithReuseIdentifier: "BetweenAnnotationView")
        return mapView
    }()

    init(searchQuery: SearchQuery, onDismiss: @escaping ((SearchQuery?) -> Void)) {
        self.onDismiss = onDismiss
        self.searchQuery = searchQuery
        self.points = searchQuery.filter.location.points
        self.manager = FilterManager(searchQuery: searchQuery)
        super.init(nibName: nil, bundle: nil)
        self.addTargets()
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
        self.view.addSubview(mapView)
        self.view.addSubview(headerView)
        self.view.addSubview(bottomView)

        headerView.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.left.right.equalTo(self.view)
        }

        bottomView.snp.makeConstraints { make in
            make.bottom.equalTo(self.view)
            make.left.right.equalTo(self.view)
        }

        mapView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.headerView.snp.bottom)
            make.bottom.equalTo(self.bottomView.snp.top)
        }

        self.mapView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MunchAnalytic.setScreen("/search/filter/between")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Register Actions
extension FilterLocationBetweenController {
    func addTargets() {
        self.headerView.closeButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)
        self.bottomView.addButton.addTarget(self, action: #selector(actionAdd(_:)), for: .touchUpInside)
        self.bottomView.applyButton.addTarget(self, action: #selector(actionApply(_:)), for: .touchUpInside)

        bottomView.pointBar.onRemove = { i in
            self.points.remove(at: i)
            self.dispatch()
        }

        self.manager.observe()
                .catchError { (error: Error) in
                    self.alert(error: error)
                    return Observable.empty()
                }
                .subscribe { event in
                    switch event {
                    case .next:
                        if self.manager.loading {
                            self.bottomView.state = .loading
                        } else if let count = self.manager.result?.count {
                            if count > 0 {
                                self.bottomView.state = .count(count, self.points.count)
                            } else {
                                self.bottomView.state = .noResult
                            }
                        }

                    case .error(let error):
                        self.alert(error: error)

                    case .completed:
                        return
                    }
                }.disposed(by: disposeBag)
        self.dispatch()
    }

    func dispatch() {
        self.bottomView.pointBar.points = self.points
        self.updateMap()

        if points.count < 2 {
            self.bottomView.state = .require2
        } else {
            self.manager.select(location: SearchQuery.Filter.Location(type: .Between, areas: [], points: points))
        }
    }

    @objc func actionCancel(_ sender: Any) {
        self.onDismiss(nil)
        self.dismiss(animated: true)
    }

    @objc func actionApply(_ sender: Any) {
        guard let count = manager.result?.count, count > 0, points.count >= 2 else {
            return
        }

        var searchQuery = self.searchQuery
        searchQuery.feature = .Search
        searchQuery.filter.location.type = .Between
        searchQuery.filter.location.points = points
        self.dismiss(animated: true)
        self.onDismiss(searchQuery)
    }

    @objc func actionAdd(_ sender: Any) {
        guard points.count < 10 else {
            return
        }

        let controller = FilterLocationBetweenSearchController(point: nil) { point in
            if let point = point {
                self.points.append(point)
                self.dispatch()
            }
        }
        self.present(controller, animated: true)
    }
}

extension FilterLocationBetweenController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        if annotation is BetweenAnnotation {
            return mapView.dequeueReusableAnnotationView(withIdentifier: "BetweenAnnotationView")
        }

        return nil
    }

    func updateMap() {
        mapView.removeAnnotations(mapView.annotations)
        self.points.forEach { point in
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocation(latLng: point.latLng)!.coordinate
            annotation.title = point.name
            mapView.addAnnotation(annotation)
        }
        let locations = self.points.compactMap { point -> CLLocation? in
            return CLLocation(latLng: point.latLng)
        }

        if locations.count > 1 {
            self.mapView.addAnnotation(BetweenAnnotation(coordinate: locations.centroid.coordinate))
        }

        self.mapView.showAnnotations(self.mapView.annotations, animated: true)
    }
}

fileprivate class BetweenAnnotation: NSObject, MKAnnotation {
    public let coordinate: CLLocationCoordinate2D

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }

    public var title: String? {
        return "Between"
    }

    public var subtitle: String? {
        return "Between"
    }
}

fileprivate class BetweenAnnotationView: MKAnnotationView {
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.canShowCallout = false

        self.image = UIImage(named: "RIP-Map-Centroid")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class FilterLocationBetweenHeaderView: UIView {
    let label = UILabel(style: .navHeader).with(text: "EatBetween")
    let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Search-Header-Close"), for: .normal)
        button.tintColor = .black
        button.imageEdgeInsets.right = 24
        button.contentHorizontalAlignment = .right
        return button
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.backgroundColor = .white

        self.addSubview(label)
        self.addSubview(closeButton)

        label.snp.makeConstraints { maker in
            maker.top.equalTo(self.safeArea.top)
            maker.bottom.equalTo(self)
            maker.height.equalTo(44)

            maker.centerX.equalTo(self)
        }

        closeButton.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(label)

            maker.right.equalTo(self)
            maker.width.equalTo(24 + 24)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: 2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class FilterLocationBetweenBottomView: UIView {
    private let titleLabel = UILabel(style: .regular)
            .with(text: "Enter everyone’s location and we’ll find the most ideal spot for a meal together.")
            .with(numberOfLines: 0)
    fileprivate let pointBar = FilterLocationBetweenBottomBar()

    fileprivate let addButton: UIButton = {
        let button = UIButton()
        button.setTitle("+ Location", for: .normal)
        button.layer.cornerRadius = 3
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.secondary500.cgColor
        button.backgroundColor = .white
        button.setTitleColor(.secondary500, for: .normal)
        button.titleLabel!.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        return button
    }()

    fileprivate let applyButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 3
        button.backgroundColor = .secondary500
        button.setTitleColor(.white, for: .normal)
        button.titleLabel!.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        return button
    }()
    fileprivate let indicator: NVActivityIndicatorView = {
        let indicator = NVActivityIndicatorView(frame: .zero, type: .ballBeat, color: .secondary500, padding: 4)
        indicator.stopAnimating()
        return indicator
    }()

    enum State {
        case loading
        case noResult
        case require2
        case count(Int, Int)
    }

    var state: State = State.loading {
        didSet {
            self.indicator.stopAnimating()

            switch state {
            case .loading:
                self.indicator.startAnimating()
                self.applyButton.setTitle(nil, for: .normal)
                self.applyButton.backgroundColor = .white

            case .noResult:
                self.applyButton.setTitle("No Results", for: .normal)
                self.applyButton.backgroundColor = .secondary050
                self.applyButton.setTitleColor(.secondary700, for: .normal)

            case .require2:
                self.applyButton.setTitle("Requires 2 Locations", for: .normal)
                self.applyButton.backgroundColor = .secondary050
                self.applyButton.setTitleColor(.secondary700, for: .normal)

            case let .count(count, points):
                self.applyButton.setTitle(FilterManager.countTitle(count: count, postfix: "Places"), for: .normal)
                self.applyButton.backgroundColor = .secondary500
                self.applyButton.setTitleColor(.white, for: .normal)

                if points < 10 {
                    self.addButton.setTitle("+ Location", for: .normal)
                } else {
                    self.addButton.setTitle("Max 10", for: .normal)
                }
            }
        }
    }

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.addSubview(titleLabel)
        self.addSubview(addButton)
        self.addSubview(applyButton)
        self.addSubview(indicator)
        self.addSubview(pointBar)
        self.state = .loading

        titleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(self).inset(16)
            maker.right.left.equalTo(self).inset(24)
        }

        pointBar.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).inset(-16)
            maker.height.equalTo(32)
            maker.right.left.equalTo(self)
        }

        addButton.snp.makeConstraints { maker in
            maker.top.equalTo(pointBar.snp.bottom).inset(-16)
            maker.left.equalTo(self).inset(24)
            maker.bottom.equalTo(self.safeArea.bottom).inset(16)
            maker.height.equalTo(40)
            maker.width.equalTo(112)
        }

        applyButton.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(addButton)

            maker.right.equalTo(self).inset(24)
            maker.left.equalTo(addButton.snp.right).inset(-16)
        }

        indicator.snp.makeConstraints { maker in
            maker.edges.equalTo(applyButton)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: -2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class FilterLocationBetweenBottomBar: UIView {
    private let titleLabel = UILabel(style: .regular)
            .with(text: "Requires 2 Locations")
            .with(numberOfLines: 0)

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = CGSize(width: 80, height: 32)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(type: FilterLocationBetweenPointCell.self)
        return collectionView
    }()

    fileprivate var onRemove: ((Int) -> Void)?
    fileprivate var points = [SearchQuery.Filter.Location.Point]() {
        didSet {
            titleLabel.isHidden = !points.isEmpty
            self.collectionView.reloadData()
        }
    }

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.addSubview(titleLabel)
        self.addSubview(collectionView)
        collectionView.delegate = self
        collectionView.dataSource = self

        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.bottom.equalTo(self)
        }

        collectionView.snp.makeConstraints { maker in
            maker.edges.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FilterLocationBetweenBottomBar: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return points.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(type: FilterLocationBetweenPointCell.self, for: indexPath)
        cell.render(with: (indexPath: indexPath, point: points[indexPath.row]))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onRemove?(indexPath.row)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return FilterLocationBetweenPointCell.size(with: (indexPath: indexPath, point: points[indexPath.row]))
    }

    fileprivate class FilterLocationBetweenPointCell: UICollectionViewCell {
        private let titleLabel = UILabel(style: .h6)
                .with(numberOfLines: 1)

        private let cancelView: UIImageView = {
            let imageView = UIImageView()
            imageView.image = UIImage(named: "Search-Filter-Location-Cancel")
            imageView.tintColor = .ba75
            imageView.contentMode = .scaleAspectFit
            return imageView
        }()

        override init(frame: CGRect = .zero) {
            super.init(frame: frame)
            self.addSubview(titleLabel)
            self.addSubview(cancelView)

            self.backgroundColor = .whisper100
            self.layer.cornerRadius = 3.0

            titleLabel.snp.makeConstraints { maker in
                maker.top.bottom.equalTo(self)
                maker.left.equalTo(self).inset(8)
            }

            cancelView.snp.makeConstraints { maker in
                maker.top.bottom.right.equalTo(self).inset(6)
            }
        }

        @discardableResult
        func render(with: (indexPath: IndexPath, point: SearchQuery.Filter.Location.Point)) -> FilterLocationBetweenPointCell {
            titleLabel.text = "\(with.indexPath.row + 1). \(with.point.name)"
            return self
        }

        static func size(with: (indexPath: IndexPath, point: SearchQuery.Filter.Location.Point)) -> CGSize {
            let text = "\(with.indexPath.row + 1). \(with.point.name)"
            let width = 8 + FontStyle.h6.width(text: text) + 4 + 24 + 6
            return CGSize(width: width, height: 32)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

