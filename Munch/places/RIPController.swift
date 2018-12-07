//
// Created by Fuxing Loh on 25/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import SafariServices

import RxSwift
import RxCocoa
import Moya

import Firebase
import Crashlytics
import SwiftRichString

import Toast_Swift

class RIPController: UIViewController {
    let placeId: String
    var data: PlaceData!

    fileprivate var headerView = RIPHeaderView(tintColor: .white, backgroundVisible: false)
    fileprivate let footerView = RIPFooterView()

    fileprivate let collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: WaterfallLayout())
        collectionView.showsVerticalScrollIndicator = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = false
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .white

        collectionView.contentInset = .zero
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    fileprivate var cardTypes: [RIPCard.Type] = [RIPLoadingImageCard.self, RIPLoadingNameCard.self]
    fileprivate var galleryItems = [RIPGalleryItem]()

    private var galleryLoader = RIPGalleryLoader()

    private let provider = MunchProvider<PlaceService>()
    private let disposeBag = DisposeBag()

    init(placeId: String) {
        self.placeId = placeId
        Crashlytics.sharedInstance().setObjectValue(placeId, forKey: "RIPController.placeId")
        super.init(nibName: nil, bundle: nil)

        self.hidesBottomBarWhenPushed = true

        self.provider.rx.request(.get(self.placeId))
                .map { res throws -> (PlaceData) in
                    return try res.map(data: PlaceData.self)
                }.subscribe { event in
                    switch event {
                    case .success(let data):
                        self.start(data: data)

                    case .error(let error):
                        self.alert(error: error)

                    }
                }.disposed(by: disposeBag)
    }

    func start(data: PlaceData) {
        RecentPlaceDatabase().add(id: self.placeId, data: data.place)

        // Data Binding
        self.data = data
        self.headerView.place = data.place
        self.footerView.place = data.place
        self.footerView.addButton.register(place: data.place, controller: self)

        galleryLoader.start(placeId: data.place.placeId, images: data.images)

        // Collection View
        self.cardTypes = self.collectionView(cellsForData: data)
        self.galleryItems = galleryLoader.items

        self.collectionView.isScrollEnabled = true
        self.collectionView.reloadData()
        self.scrollViewDidScroll(self.collectionView)

        galleryLoader.observe().subscribe { event in
            switch event {
            case .next(let items):
                self.galleryItems = items
                self.collectionView.reloadData()

            case .error(let error):
                self.alert(error: error)

            case .completed:
                return
            }
        }.disposed(by: disposeBag)
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
        self.registerCells()
        self.addTargets()

        self.view.addSubview(collectionView)
        self.view.addSubview(footerView)
        self.view.addSubview(headerView)

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }

        footerView.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(self.view)
        }

        collectionView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.view)
            make.bottom.equalTo(self.footerView.snp.top)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension RIPController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(onScreenshot), name: .UIApplicationUserDidTakeScreenshot, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationUserDidTakeScreenshot, object: nil)
    }

    @objc func onScreenshot() {
    }
}

// MARK: RIP Cards Cells
extension RIPController {
    func collectionView(cellsForData data: PlaceData) -> [RIPCard.Type] {
        var types = [RIPCard.Type]()

        func appendTo(type: RIPCard.Type) {
            if type.isAvailable(data: data) {
                types.append(type)
            }
        }

        appendTo(type: RIPImageBannerCard.self)
        appendTo(type: RIPCardClosed.self)
        appendTo(type: RIPNameTagCard.self)

        appendTo(type: RIPHourCard.self)
        appendTo(type: RIPPriceCard.self)
        appendTo(type: RIPPhoneCard.self)
        appendTo(type: RIPWebsiteCard.self)
        appendTo(type: RIPAboutFirstDividerCard.self)

        appendTo(type: RIPDescriptionCard.self)
        appendTo(type: RIPAwardCard.self)
        appendTo(type: RIPMenuWebsiteCard.self)
        appendTo(type: RIPAboutSecondDividerCard.self)

        appendTo(type: RIPLocationCard.self)
        appendTo(type: RIPSuggestEditCard.self)

        appendTo(type: RIPArticleCard.self)
        appendTo(type: RIPGalleryHeaderCard.self)
        return types
    }
}

// MARK: Collection View
extension RIPController: UICollectionViewDataSource, UICollectionViewDelegate {
    fileprivate enum RIPSection: Int, CaseIterable {
        case card = 0
        case gallery = 1
        case loader = 2
    }

    fileprivate func registerCells() {
        (collectionView.collectionViewLayout as! WaterfallLayout).delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.register(type: RIPLoadingImageCard.self)
        collectionView.register(type: RIPLoadingNameCard.self)
        collectionView.register(type: RIPLoadingGalleryCard.self)

        collectionView.register(type: RIPImageBannerCard.self)
        collectionView.register(type: RIPNameTagCard.self)
        collectionView.register(type: RIPCardClosed.self)

        collectionView.register(type: RIPHourCard.self)
        collectionView.register(type: RIPPriceCard.self)
        collectionView.register(type: RIPPhoneCard.self)
        collectionView.register(type: RIPMenuWebsiteCard.self)
        collectionView.register(type: RIPAboutFirstDividerCard.self)

        collectionView.register(type: RIPDescriptionCard.self)
        collectionView.register(type: RIPAwardCard.self)
        collectionView.register(type: RIPWebsiteCard.self)
        collectionView.register(type: RIPAboutSecondDividerCard.self)

        collectionView.register(type: RIPLocationCard.self)
        collectionView.register(type: RIPSuggestEditCard.self)

        collectionView.register(type: RIPArticleCard.self)

        collectionView.register(type: RIPGalleryHeaderCard.self)
        collectionView.register(type: RIPGalleryImageCard.self)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return RIPSection.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch RIPSection(rawValue: section)! {
        case .card:
            return cardTypes.count

        case .gallery:
            return galleryItems.count

        case .loader:
            return 1
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch (RIPSection(rawValue: indexPath.section)!, indexPath.row) {
        case (.card, let row):
            let cell = collectionView.dequeue(type: cardTypes[row], for: indexPath) as! RIPCard
            cell.register(data: self.data, controller: self)
            return cell

        case (.gallery, let row):
            switch galleryItems[row] {
            case .image(let image):
                return collectionView.dequeue(type: RIPGalleryImageCard.self, for: indexPath)
            }

        case (.loader, let row):
            return collectionView.dequeue(type: RIPLoadingGalleryCard.self, for: indexPath)

        default:
            break
        }

        return UICollectionViewCell()
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        switch (RIPSection(rawValue: indexPath.section)!, indexPath.row) {
        case (.card, let row):
            let cell = cell as! RIPCard
            cell.willDisplay(data: self.data)

        case (.gallery, let row):
            switch galleryItems[row] {
            case .image(let image):
                let cell = cell as! RIPGalleryImageCard
                cell.render(with: image)

            }

        case (.loader, let row):
            let cell = cell as! RIPLoadingGalleryCard
            if galleryLoader.more {
                galleryLoader.append()
            } else {
                cell.indicator.stopAnimating()
            }

        default:
            break
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch (RIPSection(rawValue: indexPath.section)!, indexPath.row) {
        case (.card, let row):
            let cell = collectionView.cellForItem(at: indexPath) as! RIPCard
            cell.didSelect(data: self.data, controller: self)

        default:
            break
        }
    }
}

// MARK: Waterfall
extension RIPController: WaterfallLayoutDelegate {
    public func collectionViewLayout(for section: Int) -> WaterfallLayout.Layout {
        switch RIPSection(rawValue: section)! {
        case .card:
            return .flow(column: 1)

        case .gallery:
            return .waterfall(column: 2, distributionMethod: .balanced)

        case .loader:
            return .flow(column: 1)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout: WaterfallLayout, sectionInsetFor section: Int) -> UIEdgeInsets? {
        switch RIPSection(rawValue: section)! {
        case .gallery:
            return UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)

        default:
            return UIEdgeInsets.zero
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout: WaterfallLayout, minimumInteritemSpacingFor section: Int) -> CGFloat? {
        switch RIPSection(rawValue: section)! {
        case .gallery:
            return 16

        default:
            return 0
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout: WaterfallLayout, minimumLineSpacingFor section: Int) -> CGFloat? {
        switch RIPSection(rawValue: section)! {
        case .gallery:
            return 16

        default:
            return 0
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout: WaterfallLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch (RIPSection(rawValue: indexPath.section)!, indexPath.row) {
        case (.gallery, let row):
            switch galleryItems[row] {
            case .image(let image):
                return RIPGalleryImageCard.size(image: image)
            }

        default:
            break

        }

        return WaterfallLayout.automaticSize
    }

    public func collectionView(_ collectionView: UICollectionView, layout: WaterfallLayout, estimatedSizeForItemAt indexPath: IndexPath) -> CGSize? {
        switch RIPSection(rawValue: indexPath.section)! {
        case .card:
            return CGSize(width: UIScreen.main.bounds.width, height: 250)

        case .gallery:
            let width = (UIScreen.main.bounds.width - 24 - 24 - 16) / 2
            return CGSize(width: width, height: width)

        case .loader:
            return CGSize(width: UIScreen.main.bounds.width, height: 100)
        }
    }
}

// MARK: Add Targets
extension RIPController: UIGestureRecognizerDelegate, SFSafariViewControllerDelegate {

    fileprivate func addTargets() {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        self.headerView.backButton.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)
    }

    func scrollTo(indexPath: IndexPath) {
        self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
    }

    @objc func onBackButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: Scrolling
extension RIPController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateNavigationBackground(y: scrollView.contentOffset.y)
    }

    func updateNavigationBackground(y: CGFloat) {
        func updateTint(color: UIColor) {
            headerView.tintColor = color
        }

        // Starts from - 20
        if (y < -36.0) {
            // -20 is the status bar height, another -16 is the height where it update the status bar color
            updateTint(color: .black)
            headerView.backgroundView.isHidden = true
            headerView.shadowView.isHidden = true
        } else if (155 > y) {
            // Full Opacity
            updateTint(color: .white)
            headerView.backgroundView.isHidden = true
            headerView.shadowView.isHidden = true
        } else if (175 < y) {
            // Full White
            updateTint(color: .black)
            headerView.backgroundView.isHidden = false
            headerView.backgroundView.backgroundColor = .white
            headerView.shadowView.isHidden = false
        } else {
            let progress = 1.0 - (175 - y) / 20.0
            if progress > 0.5 {
                updateTint(color: .black)
            } else {
                updateTint(color: .white)
            }
            headerView.backgroundView.isHidden = false
            headerView.backgroundView.backgroundColor = UIColor.white.withAlphaComponent(progress)
        }
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        // LightContent is white, Default is Black
        // See updateNavigationBackground for reference
        let y = self.collectionView.contentOffset.y
        if (y < -36.0) {
            return .default
        } else if (155 > y) {
            return .lightContent
        } else if (175 < y) {
            return .default
        } else {
            let progress = (1.0 - (175 - y) / 20.0)
            return progress > 0.5 ? .default : .lightContent
        }
    }
}