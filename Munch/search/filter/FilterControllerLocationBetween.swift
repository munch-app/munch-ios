//
// Created by Fuxing Loh on 2018-12-04.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import Moya
import RxSwift
import RxCocoa

import NVActivityIndicatorView

class FilterLocationBetweenController: UIViewController {
    private let onDismiss: ((SearchQuery?) -> Void)
    private let searchQuery: SearchQuery
    private var points: [SearchQuery.Filter.Location.Point?]
    private var compactPoints: [SearchQuery.Filter.Location.Point] {
        return self.points.compactMap({ $0 })
    }

    private let manager: FilterManager
    private let disposeBag = DisposeBag()

    fileprivate let headerView = FilterLocationBetweenHeaderView()
    fileprivate let bottomView = FilterLocationBetweenBottomView()

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80

        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.separatorInset.left = 24
        tableView.contentInset.bottom = 24
        return tableView
    }()

    init(searchQuery: SearchQuery, onDismiss: @escaping ((SearchQuery?) -> Void)) {
        self.onDismiss = onDismiss
        self.searchQuery = searchQuery
        self.points = searchQuery.filter.location.points
        self.manager = FilterManager(searchQuery: searchQuery)
        super.init(nibName: nil, bundle: nil)

        self.fixPoints()
        self.registerCells()
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
        self.view.addSubview(tableView)
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

        tableView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.headerView.snp.bottom)
            make.bottom.equalTo(self.bottomView.snp.top)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func fixPoints() {
        self.points = self.points.filter { point -> Bool in
            return point != nil
        }

        if self.points.count >= 10 {
            return
        }

        self.points.append(nil)
    }
}

// MARK: Register Actions
extension FilterLocationBetweenController {
    func addTargets() {
        self.headerView.closeButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)
        self.bottomView.applyButton.addTarget(self, action: #selector(actionApply(_:)), for: .touchUpInside)

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
                                self.bottomView.state = .count(count)
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
        self.fixPoints()
        let points = self.compactPoints

        if points.count < 2 {
            self.bottomView.state = .require2
        } else {
            self.manager.select(location: SearchQuery.Filter.Location(type: .Between, areas: [], points: points))
        }
        self.tableView.reloadData()
    }

    @objc func actionCancel(_ sender: Any) {
        self.onDismiss(nil)
        self.dismiss(animated: true)
    }

    @objc func actionApply(_ sender: Any) {
        guard let count = manager.result?.count, count > 0, self.compactPoints.count >= 2 else {
            return
        }

        var searchQuery = self.searchQuery
        searchQuery.filter.location.type = .Between
        searchQuery.filter.location.points = self.compactPoints
        self.onDismiss(searchQuery)
        self.dismiss(animated: true)
    }
}

// MARK: TableView Cells
extension FilterLocationBetweenController: UITableViewDataSource, UITableViewDelegate {
    func registerCells() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(type: FilterLocationBetweenHeaderCell.self)
        tableView.register(type: FilterLocationBetweenPointCell.self)
        tableView.register(type: FilterLocationBetweenPointEmptyCell.self)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section == 1 else {
            return 1
        }
        return points.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == 1 else {
            return tableView.dequeue(type: FilterLocationBetweenHeaderCell.self)
        }

        if let point = points[indexPath.row] {
            return tableView.dequeue(type: FilterLocationBetweenPointCell.self)
                    .render(with: (indexPath, point))
        } else {
            return tableView.dequeue(type: FilterLocationBetweenPointEmptyCell.self)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard indexPath.section == 1 else {
            return
        }

        if let point = points[indexPath.row] {
            self.points[indexPath.row] = nil
            self.dispatch()
        } else {
            let controller = FilterLocationBetweenSearchController(point: nil) { point in
                self.points[indexPath.row] = point
                self.dispatch()
            }
            self.present(controller, animated: true)
        }
    }
}

fileprivate class FilterLocationBetweenHeaderCell: UITableViewCell {
    private let titleLabel = UILabel(style: .regular)
            .with(text: "Enter everyone’s location to find the most convenient spot.")
            .with(numberOfLines: 0)


    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(self).inset(24)
            maker.bottom.equalTo(self).inset(16)
            maker.left.right.equalTo(self).inset(24)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class FilterLocationBetweenPointCell: UITableViewCell {
    private let titleLabel = UILabel(style: .h5)
            .with(numberOfLines: 1)
    private let cancelView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Search-Filter-Location-Cancel")
        imageView.tintColor = .ba85
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(titleLabel)
        self.addSubview(cancelView)

        titleLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self).inset(8)
            maker.height.equalTo(26)

            maker.left.equalTo(self).inset(24)
            maker.right.equalTo(cancelView.snp.left).inset(-24)

        }

        cancelView.snp.makeConstraints { maker in
            maker.right.equalTo(self).inset(24)
            maker.top.bottom.equalTo(self).inset(8)
        }
    }


    @discardableResult
    func render(with: (indexPath: IndexPath, point: SearchQuery.Filter.Location.Point)) -> FilterLocationBetweenPointCell {
        titleLabel.text = "\(with.indexPath.row + 1). \(with.point.name)"
        return self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class FilterLocationBetweenPointEmptyCell: UITableViewCell {
    let field: MunchSearchTextField = {
        let field = MunchSearchTextField()
        field.placeholder = "Add Location"
        field.isUserInteractionEnabled = false
        return field
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(field)

        field.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self).inset(12)
            maker.height.equalTo(40)
            maker.left.right.equalTo(self).inset(24)
        }
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
        case count(Int)
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
                self.applyButton.setTitle("Require 2 Locations", for: .normal)
                self.applyButton.backgroundColor = .secondary050
                self.applyButton.setTitleColor(.secondary700, for: .normal)

            case .count(let count):
                self.applyButton.setTitle(FilterManager.countTitle(count: count), for: .normal)
                self.applyButton.backgroundColor = .secondary500
                self.applyButton.setTitleColor(.white, for: .normal)

            }
        }
    }

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.addSubview(applyButton)
        self.addSubview(indicator)
        self.state = .loading

        applyButton.snp.makeConstraints { (make) in
            make.top.equalTo(self).inset(12)
            make.bottom.equalTo(self.safeArea.bottom).inset(12)
            make.right.left.equalTo(self).inset(24)
            make.height.equalTo(46)
        }

        indicator.snp.makeConstraints { make in
            make.edges.equalTo(applyButton)
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

class FilterLocationBetweenSearchController: UIViewController {
    private let onDismiss: ((SearchQuery.Filter.Location.Point?) -> Void)
    private let point: SearchQuery.Filter.Location.Point?

    private let provider = MunchProvider<SearchFilterService>()
    private let disposeBag = DisposeBag()

    private var points: [SearchQuery.Filter.Location.Point] = []

    fileprivate let headerView = FilterLocationBetweenSearchHeader()
    fileprivate let indicator: NVActivityIndicatorView = {
        let indicator = NVActivityIndicatorView(frame: .zero, type: .ballTrianglePath, color: .secondary500, padding: 0)
        indicator.startAnimating()
        return indicator
    }()

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50

        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.separatorInset.left = 24
        tableView.contentInset.top = 8
        return tableView
    }()

    /**
     * You pass in a point on init,
     * When you edited a point you return with the new point
     * When you cancel you pass back the same point
     */
    init(point: SearchQuery.Filter.Location.Point?, onDismiss: @escaping ((SearchQuery.Filter.Location.Point?) -> Void)) {
        self.onDismiss = onDismiss
        self.point = point
        super.init(nibName: nil, bundle: nil)

        self.registerCells()
        self.addTargets()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        headerView.field.becomeFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(tableView)
        self.view.addSubview(headerView)
        self.view.addSubview(indicator)

        headerView.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.left.right.equalTo(self.view)
        }

        tableView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.headerView.snp.bottom)
            make.bottom.equalTo(self.view)
        }

        indicator.snp.makeConstraints { maker in
            maker.center.equalTo(tableView)
            maker.width.height.equalTo(40)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Register Actions
extension FilterLocationBetweenSearchController {
    func addTargets() {
        self.headerView.closeButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)

        self.indicator.isHidden = true
        self.headerView.field.rx.text
                .debounce(0.3, scheduler: MainScheduler.instance)
                .distinctUntilChanged()
                .flatMapFirst { s -> Observable<[SearchQuery.Filter.Location.Point]> in
                    guard let text = s?.lowercased(), text.count > 2 else {
                        return Observable.just([])
                    }

                    self.indicator.isHidden = false
                    return self.provider.rx.request(.betweenSearch(text))
                            .map { res throws -> [SearchQuery.Filter.Location.Point] in
                                try res.map(data: [SearchQuery.Filter.Location.Point].self)
                            }
                            .asObservable()
                }
                .subscribe { event in
                    switch event {
                    case .next(let points):
                        self.points = points
                        self.indicator.isHidden = true
                        self.tableView.reloadData()

                    case .error(let error):
                        self.alert(error: error)

                    case .completed: return
                    }
                }
                .disposed(by: disposeBag)
    }

    @objc func actionCancel(_ sender: Any) {
        self.onDismiss(self.point)
        self.dismiss(animated: true)
    }
}

// MARK: TableView Cells
extension FilterLocationBetweenSearchController: UITableViewDataSource, UITableViewDelegate {
    func registerCells() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(type: FilterLocationBetweenSearchCell.self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return points.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(type: FilterLocationBetweenSearchCell.self)
        cell.render(with: points[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        self.onDismiss(points[indexPath.row])
        self.dismiss(animated: true)
    }
}

fileprivate class FilterLocationBetweenSearchCell: UITableViewCell {
    private let titleLabel = UILabel(style: .regular)
            .with(numberOfLines: 1)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self).inset(8)
            make.left.equalTo(self).inset(24)
            make.right.equalTo(self).inset(24)
        }
    }

    func render(with point: SearchQuery.Filter.Location.Point) -> FilterLocationBetweenSearchCell {
        titleLabel.text = point.name
        return self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class FilterLocationBetweenSearchHeader: UIView {
    let field: MunchSearchTextField = {
        let field = MunchSearchTextField()
        field.placeholder = "Search"
        return field
    }()
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

        self.addSubview(field)
        self.addSubview(closeButton)

        field.snp.makeConstraints { maker in
            maker.top.equalTo(self.safeArea.top).inset(12)
            maker.bottom.equalTo(self).inset(12)
            maker.height.equalTo(36)
            maker.left.equalTo(self).inset(24)
            maker.right.equalTo(closeButton.snp.left).inset(-16)
        }

        closeButton.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(field)

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