//
// Created by Fuxing Loh on 19/8/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import Moya

import Toast_Swift
import Localize_Swift
import NVActivityIndicatorView

import FirebaseAnalytics

class UserPlaceCollectionController: UIViewController {
    private let headerView = HeaderView()
    private let tableView = UITableView()

    private let disposeBag = DisposeBag()
    private let collectionDatabase = UserPlaceCollectionDatabase()
    private let itemDatabase = UserPlaceCollectionItemDatabase()
    private let provider = MunchProvider<UserPlaceCollectionService>()

    private var collection: UserPlaceCollection?
    private var collectionId: String?

    private var items: [UserPlaceCollectionItem] = [.loading]
    private var loader: PlaceCollectionLoader?

    init(collection: UserPlaceCollection) {
        self.collection = collection
        super.init(nibName: nil, bundle: nil)
    }

    init(collectionId: String) {
        self.collectionId = collectionId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        self.registerCell()

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.headerView.backButton.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)

        if let collection = collection {
            self.headerView.titleView.text = collection.name
            itemDatabase.observe(collection: collection).subscribe { event in
                switch event {
                case .next(let items):
                    self.items = items.compactMap({
                        if let place = $0.place {
                            return UserPlaceCollectionItem.place($0, place)
                        }
                        return nil
                    })
                    self.tableView.reloadData()

                case .error(let error):
                    self.alert(error: error)
                case .completed:
                    return
                }
            }.disposed(by: disposeBag)
        } else if let collectionId = collectionId {
            self.loader = PlaceCollectionLoader()

            loader!.observe(collectionId: collectionId) { collection, error in
                        if let collection = collection {
                            self.collection = collection
                            self.headerView.titleView.text = collection.name
                        } else if let error = error {
                            self.alert(error: error)
                        }
                    }
                    .subscribe { event in
                        switch event {
                        case let .next(items, more):
                            self.items = items.compactMap({
                                if let place = $0.place {
                                    return UserPlaceCollectionItem.place($0, place)
                                }
                                return nil
                            })
                            if more {
                                self.items.append(.loading)
                            }
                            self.tableView.reloadData()

                        case .error(let error):
                            self.alert(error: error)
                        case .completed:
                            return
                        }
                    }
                    .disposed(by: disposeBag)
        }
    }

    private func initViews() {
        self.view.addSubview(tableView)
        self.view.addSubview(headerView)

        tableView.separatorStyle = .none
        tableView.separatorInset.left = 24
        tableView.allowsSelection = true
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.sectionHeaderHeight = 44
        tableView.estimatedRowHeight = 50

        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 12))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 12))
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.left.right.equalTo(self.view)
        }

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }
    }

    @objc func onBackButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    private class HeaderView: UIView {
        fileprivate let backButton: UIButton = {
            let backButton = UIButton()
            backButton.setImage(UIImage(named: "NavigationBar-Back"), for: .normal)
            backButton.tintColor = .black
            backButton.imageEdgeInsets.left = 18
            backButton.contentHorizontalAlignment = .left
            return backButton
        }()
        fileprivate let titleView: UILabel = {
            let titleView = UILabel()
            titleView.font = .systemFont(ofSize: 17, weight: .regular)
            titleView.textAlignment = .center
            return titleView
        }()

        override init(frame: CGRect = CGRect.zero) {
            super.init(frame: frame)
            self.initViews()
        }

        private func initViews() {
            self.backgroundColor = .white
            self.addSubview(titleView)
            self.addSubview(backButton)

            titleView.snp.makeConstraints { make in
                make.centerX.equalTo(self)
                make.top.equalTo(self.safeArea.top)
                make.bottom.equalTo(self)
                make.height.equalTo(44)
            }

            backButton.snp.makeConstraints { make in
                make.top.equalTo(self.safeArea.top)
                make.left.equalTo(self)
                make.bottom.equalTo(self)
                make.width.equalTo(64)
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            self.hairlineShadow(height: 1.0)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

fileprivate enum UserPlaceCollectionItem {
    case loading
    case place(UserPlaceCollection.Item, Place)
}

extension UserPlaceCollectionController: UITableViewDataSource, UITableViewDelegate {
    func registerCell() {
        func register(cellClass: UITableViewCell.Type) {
            tableView.register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
        }

        register(cellClass: UserPlaceCollectionLoadingCell.self)
        register(cellClass: UserPlaceCollectionItemCell.self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        func dequeue(cellClass: UITableViewCell.Type) -> UITableViewCell {
            let identifier = String(describing: cellClass)
            return tableView.dequeueReusableCell(withIdentifier: identifier)!
        }

        switch items[indexPath.row] {
        case .loading:
            return dequeue(cellClass: UserPlaceCollectionLoadingCell.self)
        case let .place(item, place):
            return dequeue(cellClass: UserPlaceCollectionItemCell.self)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch items[indexPath.row] {
        case let .place(_, place):
            let controller = PlaceController(place: place)
            self.navigationController?.pushViewController(controller, animated: true)

        default:
            return
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch items[indexPath.row] {
        case .loading:
            self.loader?.loadMore()

        case let .place(item, place):
            (cell as? UserPlaceCollectionItemCell)?.render(item: item, place: place) {
                self.actionMore(item: item)
            }
        }
    }

    private func actionMore(item: UserPlaceCollection.Item) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Remove", style: .default, handler: { action in
            self.actionRemove(item: item)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        self.present(alert, animated: true)
    }

    private func actionRemove(item: UserPlaceCollection.Item) {
        self.view.makeToastActivity(.center)

        guard let collection = collection else {
            return
        }

        itemDatabase.remove(collection: collection, placeId: item.placeId) { error in
            self.view.hideToastActivity()

            if let error = error {
                self.alert(error: error)
                return
            }
            self.makeToast("Removed from \(collection.name)", image: .close)
        }
    }
}

fileprivate class UserPlaceCollectionLoadingCell: UITableViewCell {
    private var indicator: NVActivityIndicatorView!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: UIScreen.main.bounds.width, height: 40))
        self.indicator = NVActivityIndicatorView(frame: frame, type: .ballBeat, color: .primary700, padding: 0)
        indicator.startAnimating()
        self.addSubview(indicator)

        indicator.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.height.equalTo(40)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class UserPlaceCollectionItemCell: UITableViewCell {
    private let leftImageView: SizeShimmerImageView = {
        let imageView = SizeShimmerImageView(points: 60, height: 60)
        return imageView
    }()

    private let titleView: UILabel = {
        let titleView = UILabel()
        titleView.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleView.textColor = UIColor.black.withAlphaComponent(0.8)
        return titleView
    }()

    private let tagView = MunchTagView(count: 4)
    private let tagTokenConfig = DefaultTagViewConfig()

    private let locationLabel: UILabel = {
        let locationLabel = UILabel()
        locationLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        locationLabel.textColor = UIColor.black.withAlphaComponent(0.75)
        return locationLabel
    }()
    private let moreButton: UIButton = {
        let button = UIButton()
        button.tintColor = .black
        button.setImage(UIImage(named: "Collection-More"), for: .normal)
        button.imageEdgeInsets.right = 18
        button.imageEdgeInsets.bottom = 12
        return button
    }()

    private var onMoreAction: (() -> Void)?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(leftImageView)
        self.addSubview(moreButton)
        self.addSubview(titleView)
        self.addSubview(tagView)
        self.addSubview(locationLabel)

        leftImageView.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(12)
            make.width.equalTo(120)
            make.height.equalTo(120)
        }

        titleView.snp.makeConstraints { make in
            make.left.equalTo(leftImageView.snp.right).inset(-12)
            make.right.equalTo(self).inset(24)

            make.top.equalTo(self).inset(12 + 6)
        }

        tagView.snp.makeConstraints { (make) in
            make.left.equalTo(leftImageView.snp.right).inset(-12)
            make.right.equalTo(self).inset(24)

            make.height.equalTo(24)
            make.top.equalTo(titleView.snp.bottom).inset(-6)
        }

        locationLabel.snp.makeConstraints { make in
            make.left.equalTo(leftImageView.snp.right).inset(-12)
            make.right.equalTo(self).inset(24)

            make.height.equalTo(19)
            make.top.equalTo(tagView.snp.bottom).inset(-6)
        }

        moreButton.addTarget(self, action: #selector(onMoreButton(_:)), for: .touchUpInside)
        moreButton.snp.makeConstraints { make in
            make.height.equalTo(24 + moreButton.imageEdgeInsets.bottom + moreButton.imageEdgeInsets.top)
            make.width.equalTo(24 + moreButton.imageEdgeInsets.right + moreButton.imageEdgeInsets.left)
            make.right.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(item: UserPlaceCollection.Item, place: Place, onMoreAction: @escaping(() -> Void)) {
        self.onMoreAction = onMoreAction
        self.leftImageView.render(image: place.images.get(0))
        self.titleView.text = place.name

        self.render(tag: place)
        self.render(location: place)
    }

    private func render(tag place: Place) {
        self.tagView.removeAll()
        if let price = place.price?.perPax {
            self.tagView.add(text: "~$\(price)", config: PriceTagViewConfig())
        }

        for tag in place.tags.prefix(3) {
            self.tagView.add(text: tag.name, config: DefaultTagViewConfig())
        }
    }

    private func render(location place: Place) {
        let line = NSMutableAttributedString()

        if let latLng = place.location.latLng, let distance = MunchLocation.distance(asMetric: latLng) {
            line.append(NSAttributedString(string: "\(distance) - "))
        }

        if let neighbourhood = place.location.neighbourhood {
            line.append(NSAttributedString(string: neighbourhood))
        } else {
            line.append(NSAttributedString(string: "Singapore"))
        }
        self.locationLabel.attributedText = line
    }

    @objc func onMoreButton(_ sender: Any) {
        self.onMoreAction?()
    }
}