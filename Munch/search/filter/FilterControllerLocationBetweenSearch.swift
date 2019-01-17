//
// Created by Fuxing Loh on 2019-01-17.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import SnapKit

import Moya
import RxSwift
import RxCocoa

import NVActivityIndicatorView

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
                .flatMapLatest { s -> Observable<[SearchQuery.Filter.Location.Point]> in
                    guard let text = s?.lowercased(), text.count > 1 else {
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
            make.top.bottom.equalTo(self).inset(10)
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