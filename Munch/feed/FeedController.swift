//
// Created by Fuxing Loh on 2018-11-30.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

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

        collectionView.register(type: FeedCellHeader.self)
        collectionView.register(type: FeedCellImage.self)
        collectionView.register(type: FeedCellLoading.self)
        return collectionView
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

        headerView.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(self.view)
            maker.bottom.equalTo(self.view.safeArea.top)
        }

        collectionView.snp.makeConstraints { maker in
            maker.left.right.bottom.equalTo(self.view)
            maker.top.equalTo(headerView)
        }

        (collectionView.collectionViewLayout as! WaterfallLayout).delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self

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
    }
}

extension FeedController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
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
            switch items[row] {
            case let .image(item, _):
                return collectionView.dequeue(type: FeedCellImage.self, for: indexPath)
                        .render(with: item)
            }

        case (2, _):
            return collectionView.dequeue(type: FeedCellLoading.self, for: indexPath)

        default:
            return UICollectionViewCell()
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            self.manager.append()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (1, let row):
            switch items[row] {
            case let .image(item, places):
                let controller = FeedImageController(item: item, places: places)
                self.navigationController?.pushViewController(controller, animated: true)
            }

        default:
            break
        }
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
            return UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        case 1:
            return UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        case 2:
            return UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
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

class FeedHeaderView: UIView {
    required init() {
        super.init(frame: .zero)
        self.backgroundColor = .white
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: 1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}