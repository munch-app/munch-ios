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
        self.bottomView.applyButton.addTarget(self, action: #selector(actionApply(_:)), for: .touchUpInside)
        self.bottomView.pointList.searchBar.addTarget(self, action: #selector(actionAdd(_:)), for: .touchUpInside)

        bottomView.pointList.onRemove = { i in
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
        self.bottomView.pointList.points = self.points
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

        let controller = SearchLocationRootController { loc in
            if let loc = loc {
                self.points.append(SearchQuery.Filter.Location.Point(name: loc.name, latLng: loc.latLng))
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
            .with(text: "Enter everyone’s location to find the most ideal spot for a meal together. ")
            .with(numberOfLines: 0)
    fileprivate let pointList = FilterLocationBetweenPointList()

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
                self.applyButton.setTitle("Requires at least 2 locations", for: .normal)
                self.applyButton.backgroundColor = .white
                self.applyButton.setTitleColor(.black, for: .normal)

            case let .count(count, points):
                self.applyButton.setTitle(FilterManager.countTitle(count: count, postfix: "Places"), for: .normal)
                self.applyButton.backgroundColor = .secondary500
                self.applyButton.setTitleColor(.white, for: .normal)
            }
        }
    }

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.addSubview(titleLabel)
        self.addSubview(applyButton)
        self.addSubview(indicator)
        self.addSubview(pointList)
        self.state = .loading

        titleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(self).inset(16)
            maker.right.left.equalTo(self).inset(24)
        }

        pointList.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).inset(-8)
            maker.right.left.equalTo(self)
        }

        applyButton.snp.makeConstraints { maker in
            maker.top.equalTo(pointList.snp.bottom).inset(-16)
            maker.bottom.equalTo(self.safeArea.bottom).inset(16)
            maker.height.equalTo(40)

            maker.left.right.equalTo(self).inset(24)
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

fileprivate class FilterLocationBetweenPointList: UIView {
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50

        tableView.tableFooterView = UIView(frame: .zero)

        tableView.contentInset = .zero
//        tableView.contentInset.top = 8
        tableView.separatorStyle = .none
        tableView.register(type: FilterLocationBetweenPointCell.self)
        return tableView
    }()
    let searchBar = SelectLocationButton()

    var tableViewSearchBarConstraint: Constraint?
    var height8Constraint: Constraint?
    var height100Constraint: Constraint?
    var height160Constraint: Constraint?

    fileprivate var onRemove: ((Int) -> Void)?
    fileprivate var points = [SearchQuery.Filter.Location.Point]() {
        didSet {
            self.tableView.reloadData()

            if self.points.isEmpty {
                self.searchBar.isHidden = false
                tableViewSearchBarConstraint?.activate()
                height8Constraint?.activate()
                height100Constraint?.deactivate()
                height160Constraint?.deactivate()
            } else if (self.points.count < 10) {
                self.searchBar.isHidden = false
                tableViewSearchBarConstraint?.activate()

                height8Constraint?.deactivate()

                if (self.points.count < 5) {
                    height100Constraint?.activate()
                    height160Constraint?.deactivate()
                } else {
                    height100Constraint?.deactivate()
                    height160Constraint?.activate()
                }

            } else {
                self.searchBar.isHidden = true
                tableViewSearchBarConstraint?.deactivate()
            }
        }
    }

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.addSubview(tableView)
        self.addSubview(searchBar)

        tableView.delegate = self
        tableView.dataSource = self

        tableView.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(self)
            height8Constraint = maker.height.equalTo(8).constraint
            height100Constraint = maker.height.equalTo(100).constraint
            height160Constraint = maker.height.equalTo(160).constraint
            maker.bottom.equalTo(self).priority(.high)
            tableViewSearchBarConstraint = maker.bottom.equalTo(searchBar.snp.top).constraint
        }

        searchBar.snp.makeConstraints { maker in
            maker.bottom.equalTo(self)
            maker.left.right.equalTo(self).inset(24)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FilterLocationBetweenPointList: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return points.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(type: FilterLocationBetweenPointCell.self)
        cell.render(with: (indexPath: indexPath, point: points[indexPath.row]))
        cell.view.closeIcon.control.onTouchUpInside { _ in
            self.onRemove?(indexPath.row)
        }
        return cell
    }

    fileprivate class FilterLocationBetweenPointCell: UITableViewCell {
        let view = EatBetweenPoint()

        override init(style: CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            self.addSubview(view)

            view.snp.makeConstraints { maker in
                maker.top.bottom.equalTo(self)
                maker.left.right.equalTo(self).inset(24)
            }
        }

        @discardableResult
        func render(with: (indexPath: IndexPath, point: SearchQuery.Filter.Location.Point)) -> FilterLocationBetweenPointCell {
            view.label.text = with.point.name
            return self
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

class SelectLocationButton: UIButton {
    private let icon = PaddingWidget(
            top: 8, bottom: 8, left: 8,
            view: IconWidget(size: 24, image: UIImage(named: "Location_Pin"), tintColor: .ba60)
    )
    private let title = PaddingWidget(
            all: 8,
            view: UILabel(style: .regular).with(text: "Enter location").with(color: .ba60)
    )

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(icon)
        self.addSubview(title)
        self.layer.cornerRadius = 4.0
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.ba20.cgColor

        self.title.view.isUserInteractionEnabled = false
        self.icon.view.isUserInteractionEnabled = false

        icon.snp.makeConstraints { maker in
            maker.left.top.bottom.equalTo(self)
        }

        title.snp.makeConstraints { maker in
            maker.right.top.bottom.equalTo(self)
            maker.left.equalTo(icon.snp.right)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class EatBetweenPoint: UIView {
    private let pinIcon = PaddingWidget(
            all: 8,
            view: IconWidget(size: 24, image: UIImage(named: "Location_Pin"), tintColor: .primary500)
    )
    fileprivate let closeIcon = ControlWidget(PaddingWidget(
            top: 10, bottom: 10, left: 8,
            view: IconWidget(size: 20, image: UIImage(named: "Location_Cancel"))
    ))
    private let separator = SeparatorLine()
    let label = UILabel(style: .regular)
            .with(text: "Enter location")
            .with(numberOfLines: 1)

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(pinIcon)
        self.addSubview(closeIcon)
        self.addSubview(separator)
        self.addSubview(label)

        pinIcon.snp.makeConstraints { maker in
            maker.left.top.bottom.equalTo(self)
        }

        label.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self).inset(10)
            maker.left.equalTo(pinIcon.snp.right)
            maker.right.equalTo(closeIcon.snp.left)
        }

        separator.snp.makeConstraints { maker in
            maker.bottom.equalTo(self)
            maker.left.right.equalTo(label)
        }

        closeIcon.snp.makeConstraints { maker in
            maker.right.top.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



