//
// Created by Fuxing Loh on 2018-11-30.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import SafariServices

import RxSwift
import RxCocoa

import SwiftRichString

class FeedRootController: UINavigationController, UINavigationControllerDelegate {
    let controller = FeedController()

    required init() {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [controller]
        self.delegate = self
    }

    // Fix bug when pop gesture is enabled for the root controller
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        self.interactivePopGestureRecognizer?.isEnabled = self.viewControllers.count > 1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FeedController: UIViewController {
    private let headerView = FeedHeaderView()
    private let collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: WaterfallLayout())
        collectionView.showsVerticalScrollIndicator = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = false
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .white

        collectionView.contentInsetAdjustmentBehavior = .automatic
        collectionView.contentInset.top = 56
        return collectionView
    }()
    private let refreshView: UIRefreshControl = {
        let control = UIRefreshControl()
        control.tintColor = UIColor.secondary500
        return control
    }()

    private var items: [FeedCellItem] = []

    private let manager = FeedManager()
    private let disposeBag = DisposeBag()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(collectionView)
        self.view.addSubview(headerView)
        self.collectionView.addSubview(refreshView)

        self.addTargets()

        headerView.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(self.view)
        }

        collectionView.snp.makeConstraints { maker in
            maker.top.left.right.bottom.equalTo(self.view)
        }

        self.registerCells()

        self.manager.observe()
                .catchError { (error: Error) in
                    self.alert(error: error)
                    return Observable.empty()
                }
                .subscribe { event in
                    switch event {
                    case .next(let items):
                        self.items = items
                        self.collectionView.reloadData()

                    case .error(let error):
                        self.alert(error: error)

                    case .completed:
                        return
                    }
                }.disposed(by: disposeBag)
        self.manager.reset()
    }
}

// MARK: Targets
extension FeedController {
    func addTargets() {
        self.refreshView.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        self.headerView.searchBar.addTarget(self, action: #selector(onLocation), for: .touchUpInside)
        self.headerView.closeBtn.addTarget(self, action: #selector(clearLocation), for: .touchUpInside)
    }

    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.reset()
        refreshControl.endRefreshing()
    }

    @objc func onLocation() {
        let controller = SearchLocationRootController { location in
            if let location = location {
                self.headerView.with(name: location.name)
                self.manager.reset(latLng: location.latLng)
                self.scrollToTop()
            }
        }
        self.present(controller, animated: true)
    }

    @objc func clearLocation() {
        self.reset()
    }

    func reset() {
        self.headerView.with(name: nil)
        self.manager.reset()
        self.scrollToTop()
    }

    @discardableResult
    func scrollToTop(animated: Bool = true) -> Bool {
        let top = self.collectionView.contentOffset.y <= 0
        self.collectionView.setContentOffset(CGPoint(x: 0, y: -100), animated: true)
        return top
    }
}

// MARK: NotificationCenter
extension FeedController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MunchAnalytic.setScreen("/feed")

        DispatchQueue.main.async {
            UserDefaults.notify(key: .notifyFeedWelcome) {
                self.show(title: "Welcome to the Munch Feed!", message: "See something you like? Click on any image to find out more.")
            }
        }

        NotificationCenter.default.addObserver(self,
                selector: #selector(applicationWillEnterForeground(_:)),
                name: NSNotification.Name.UIApplicationWillEnterForeground,
                object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self,
                name: NSNotification.Name.UIApplicationWillEnterForeground,
                object: nil)
    }

    @objc func applicationWillEnterForeground(_ notification: NSNotification) {
        if let date = UserDefaults.standard.object(forKey: UserDefaultsKey.globalResignActiveDate.rawValue) as? Date {
            if Date().millis - date.millis > 1000 * 60 * 60 {
                self.reset()
            }
        }
    }
}

// MARK: Register Cells
extension FeedController: UICollectionViewDataSource, UICollectionViewDelegate, SFSafariViewControllerDelegate {
    func registerCells() {
        (collectionView.collectionViewLayout as! WaterfallLayout).delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.register(type: FeedCellHeader.self)
        collectionView.register(type: FeedCellImage.self)

        collectionView.register(type: FeedCellLoading.self)
        collectionView.register(type: FeedCellNoResult.self)
        collectionView.register(type: FeedCellEmpty.self)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 0
        case 1:
            return items.count

        default:
            return 1
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0, _):
            return collectionView.dequeue(type: FeedCellHeader.self, for: indexPath)

        case (1, let row):
            let cellItem: FeedCellItem = items[row]
            switch cellItem {
            case let .image(item, places):
                return collectionView.dequeue(type: FeedCellImage.self, for: indexPath)
                        .render(with: item, places: places) {
                            self.onMoreItem(item: cellItem)
                        }
            }

        case (2, _) where manager.more:
            return collectionView.dequeue(type: FeedCellLoading.self, for: indexPath)

        case (2, _) where manager.items.isEmpty:
            return collectionView.dequeue(type: FeedCellNoResult.self, for: indexPath)

        default:
            return collectionView.dequeue(type: FeedCellEmpty.self, for: indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (1, let row):
            let cellItem: FeedCellItem = items[row]
            switch cellItem {
            case let .image(item, _):
                MunchAnalytic.logEvent("feed_item_view", parameters: [
                    "type": item.type.rawValue as NSObject
                ])
            }
        case (2, _):
            self.manager.append()

        default:
            return
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (1, let row):
            let cellItem: FeedCellItem = items[row]
            switch cellItem {
            case let .image(item, places):
                self.onItem(item: item, places: places)
            }

        default:
            break
        }
    }

    func onMoreItem(item: FeedCellItem) {
        switch item {
        case let .image(item, places):
            guard let place: Place = places.get(0) else {
                return
            }

            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            if let author = item.author, let link = item.instagram?.link, let url = URL(string: link) {
                alert.addAction(UIAlertAction(title: "More from \(author)", style: .default) { action in
                    let alert = UIAlertController(title: nil, message: "Open Instagram?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    alert.addAction(UIAlertAction(title: "Open", style: .default) { action in
                        let safari = SFSafariViewController(url: url)
                        safari.delegate = self
                        self.present(safari, animated: true, completion: nil)
                    })
                    self.present(alert, animated: true)
                })
            }

            alert.addAction(UIAlertAction(title: "View place", style: .default) { action in
                self.onItem(item: item, places: places)
            })
            alert.addAction(UIAlertAction(title: "Save place", style: .default) { action in
                Authentication.requireAuthentication(controller: controller) { state in
                    guard case .loggedIn = state else {
                        return
                    }

                    PlaceSavedDatabase.shared.put(placeId: place.placeId).subscribe { (event: SingleEvent<Bool>) in
                        switch event {
                        case .success:
                            UIImpactFeedbackGenerator().impactOccurred()
                            self.view.makeToast("Added '\(place.name)' to your places.")
                            MunchAnalytic.logEvent("rip_heart_saved")

                        case .error(let error):
                            self.alert(error: error)
                        }
                    }.disposed(by: self.disposeBag)
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alert, animated: true)
        }
    }

    func onItem(item: FeedItem, places: [Place]) {
        guard let sizes = item.image?.sizes, let instagram = item.instagram else {
            return
        }
        guard let placeId = places.get(0)?.placeId else {
            return
        }

        MunchAnalytic.logEvent("feed_item_click", parameters: [
            "type": item.type.rawValue as NSObject
        ])

        let image = CreditedImage(sizes: sizes, name: instagram.username, link: instagram.link)
        let controller = RIPController(placeId: placeId, focusedImage: image)
        self.navigationController?.pushViewController(controller, animated: true)
    }
}

extension FeedController: WaterfallLayoutDelegate {
    func collectionViewLayout(for section: Int) -> WaterfallLayout.Layout {
        switch section {
        case 1:
            return .waterfall(column: 2, distributionMethod: .balanced)

        default:
            return .flow(column: 1)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout: WaterfallLayout, sectionInsetFor section: Int) -> UIEdgeInsets? {
        switch section {
        case 0:
            return UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16)
        case 1:
            return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        case 2:
            return UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)
        default:
            return UIEdgeInsets.zero
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout: WaterfallLayout, minimumInteritemSpacingFor section: Int) -> CGFloat? {
        if section == 1 {
            return 16
        }
        return 0
    }

    public func collectionView(_ collectionView: UICollectionView, layout: WaterfallLayout, minimumLineSpacingFor section: Int) -> CGFloat? {
        if section == 1 {
            return 16
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout: WaterfallLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch indexPath.section {
        case 1:
            switch items[indexPath.row] {
            case .image(let image, _):
                return FeedCellImage.size(item: image)
            }

        default:
            return WaterfallLayout.automaticSize
        }
    }
}

// MARK: Scroll delegate
extension FeedController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        self.headerView.shadow.isHidden = scrollView.contentOffset.y < 30
    }
}

class FeedHeaderView: UIView {
    let searchBar = UIControl()
    let textBar = UILabel(style: .h6)
            .with(numberOfLines: 1)

    let closeBtn = ControlWidget(
            PaddingWidget(
                    all: 10, view: IconWidget(size: 14, image: UIImage(named: "Search-Header-Close"))
            )
    )

    required init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor(white: 1, alpha: 0.97)
        self.addSubview(searchBar)
        self.addSubview(textBar)
        self.addSubview(closeBtn)

        searchBar.backgroundColor = .whisper100
        searchBar.layer.cornerRadius = 4
        searchBar.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(16)
            maker.top.equalTo(self.safeArea.top).inset(10)
            maker.bottom.equalTo(self).inset(10)
            maker.height.equalTo(36)
        }

        closeBtn.snp.makeConstraints { maker in
            maker.right.equalTo(searchBar)
            maker.centerY.equalTo(searchBar)
        }

        with(name: nil)
        textBar.snp.makeConstraints { maker in
            maker.left.equalTo(searchBar).inset(14)
            maker.right.equalTo(closeBtn.snp.left).inset(14)
            maker.centerY.equalTo(searchBar)
        }
    }

    func with(name: String?) {
        if let name = name {
            self.textBar.text = name
            self.textBar.with(color: .ba85)
            self.closeBtn.isHidden = false
        } else {
            self.textBar.text = "Discover by location"
            self.textBar.with(color: .ba60)
            self.closeBtn.isHidden = true
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}