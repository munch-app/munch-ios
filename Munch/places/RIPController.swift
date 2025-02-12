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
    var focusedImage: CreditedImage?

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
    fileprivate var galleryItems = [RIPImageItem]()

    private var imageLoader = RIPImageLoader()

    private let provider = MunchProvider<PlaceService>()
    private let recentService = MunchProvider<UserRecentPlaceService>()
    private let disposeBag = DisposeBag()

    init(placeId: String, focusedImage: CreditedImage? = nil) {
        self.placeId = placeId
        self.focusedImage = focusedImage
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
        if Authentication.isAuthenticated() {
            self.recentService.rx.request(.put(self.placeId)).subscribe { event in
                switch event {
                case .success: return

                case .error(let error):
                    self.alert(error: error)
                }
            }.disposed(by: disposeBag)
        }

        // Setting Focused Image
        if self.focusedImage == nil, let image = data.images.get(0) {
            if let instagram = image.instagram {
                self.focusedImage = CreditedImage(sizes: image.sizes, name: instagram.username, link: instagram.link)
            } else if let article = image.article {
                self.focusedImage = CreditedImage(sizes: image.sizes, name: article.domain.name, link: article.url)
            } else {
                self.focusedImage = CreditedImage(sizes: image.sizes, name: nil, link: nil)
            }
        }


        // Data Binding
        self.data = data
        self.headerView.place = data.place
        self.headerView.addTargets(controller: self)

        self.footerView.place = data.place
        self.footerView.addButton.register(place: data.place, savedPlace: data.user?.savedPlace, controller: self)

        imageLoader.start(placeId: data.place.placeId, images: data.images)

        // Collection View
        self.cardTypes = self.collectionView(cellsForData: data)
        self.galleryItems = imageLoader.items

        self.collectionView.isScrollEnabled = true
        self.collectionView.reloadData()
        self.scrollViewDidScroll(self.collectionView)

        imageLoader.observe().subscribe { event in
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
        MunchAnalytic.setScreen("/places")
        MunchAnalytic.logEvent("rip_view")

        UserDefaults.count(key: .countViewRip)

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
        appendTo(type: RIPCardStatus.self)
        appendTo(type: RIPCardPreference.self)
        appendTo(type: RIPNameTagCard.self)
        appendTo(type: RIPCardRating.self)

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
        collectionView.register(type: RIPGalleryFooterCard.self)

        collectionView.register(type: RIPImageBannerCard.self)
        collectionView.register(type: RIPNameTagCard.self)
        collectionView.register(type: RIPCardPreference.self)
        collectionView.register(type: RIPCardStatus.self)
        collectionView.register(type: RIPCardRating.self)

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
            return galleryItems.count > 0 ? 1 : 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch (RIPSection(rawValue: indexPath.section)!, indexPath.row) {
        case (.card, let row):
            let cell = collectionView.dequeue(type: cardTypes[row], for: indexPath)
            cell.register(data: self.data, controller: self)
            return cell

        case (.gallery, let row):
            switch galleryItems[row] {
            case .image:
                return collectionView.dequeue(type: RIPGalleryImageCard.self, for: indexPath)
            }

        case (.loader, _):
            let cell = collectionView.dequeue(type: RIPGalleryFooterCard.self, for: indexPath)
            cell.register(data: self.data, controller: self)
            return cell
        }
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        switch (RIPSection(rawValue: indexPath.section)!, indexPath.row) {
        case (.card, _):
            let cell = cell as! RIPCard
            cell.willDisplay(data: self.data)

        case (.gallery, let row):
            switch galleryItems[row] {
            case .image(let image):
                let cell = cell as! RIPGalleryImageCard
                cell.render(with: image)

            }

        case (.loader, _):
            let cell = cell as! RIPGalleryFooterCard
            if imageLoader.more {
                imageLoader.append()
            } else {
                cell.loading = false
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch (RIPSection(rawValue: indexPath.section)!, indexPath.row) {
        case (.card, _):
            let cell = collectionView.cellForItem(at: indexPath) as! RIPCard
            cell.didSelect(data: self.data, controller: self)

        case (.gallery, let row):
            let controller = RIPImageController(index: row, loader: self.imageLoader, place: self.data.place)
            controller.modalPresentationStyle = .overCurrentContext
            self.present(controller, animated: true)

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

        self.headerView.backControl.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)
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
        switch self.preferredStatusBarStyle {
        case .default:
            headerView.tintColor = .black
            headerView.backgroundView.isHidden = false
            headerView.shadowView.isHidden = false

        case .lightContent:
            headerView.tintColor = .white
            headerView.backgroundView.isHidden = true
            headerView.shadowView.isHidden = true
        }
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        if self.focusedImage == nil {
            return .default
        }

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