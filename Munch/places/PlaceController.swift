//
// Created by Fuxing Loh on 25/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

import RxSwift
import RxCocoa
import Moya

import SnapKit
import Firebase
import Crashlytics
import SwiftRichString

import Cosmos
import Toast_Swift

class PlaceController: UIViewController {
    let placeId: String
    var place: Place?
    var tracker: UserPlaceActivityTracker?

    let provider = MunchProvider<PlaceService>()
    let disposeBag = DisposeBag()

    private var cards = [PlaceShimmerImageBannerCard.card, PlaceShimmerNameTagCard.card]
    private var cells = [PlaceCardView]()
    private var cellTypes = [String: PlaceCardView.Type]()
    private var cellHeights = [CGFloat](repeating: UITableViewAutomaticDimension, count: 100)

    fileprivate let cardTableView = UITableView()
    fileprivate var headerView: PlaceHeaderView!
    fileprivate let bottomView = PlaceBottomView()

    fileprivate let contentView = UIView()

    convenience init(place: Place) {
        self.init(placeId: place.placeId, place: place)
    }

    init(placeId: String, place: Place?) {
        self.placeId = placeId
        self.place = place
        Crashlytics.sharedInstance().setObjectValue(placeId, forKey: "PlaceController.placeId")
        super.init(nibName: nil, bundle: nil)

        self.hidesBottomBarWhenPushed = true
        self.headerView = PlaceHeaderView(controller: self, place: place, tintColor: .white, backgroundVisible: false, titleHidden: true)
        self.cells = [PlaceShimmerImageBannerCard.create(controller: self), PlaceShimmerNameTagCard.create(controller: self)]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        NotificationCenter.default.addObserver(self, selector: #selector(handleScreenshot), name: .UIApplicationUserDidTakeScreenshot, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationUserDidTakeScreenshot, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCards()
        self.initViews()

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        self.cardTableView.delegate = self
        self.cardTableView.dataSource = self

        provider.rx.request(.cards(self.placeId))
                .map { response throws -> ([PlaceCard], Place) in
                    let cards = try response.mapJSON(atDataKeyPath: "cards") as? [[String: Any]]
                    let place = try response.map(data: Place.self, atKeyPath: "place")

                    if let cards = cards, let place = place {
                        return (cards.map({ PlaceCard(dictionary: $0) }), place)
                    }

                    throw MoyaError.jsonMapping(response)
                }.subscribe { event in
                    switch event {
                    case .success(let cards, let place):
                        RecentPlaceDatabase().add(id: place.placeId, data: place)

                        self.cards = cards
                        self.place = place
                        self.tracker = UserPlaceActivityTracker(place: place)

                        self.headerView.place = place
                        self.bottomView.place = place

                        self.cells = self.create(cards: cards)
                        self.cardTableView.isScrollEnabled = true
                        self.cardTableView.reloadData()
                        self.scrollViewDidScroll(self.cardTableView)
                    case .error(let error):
                        self.alert(error: error)
                    }
                }.disposed(by: disposeBag)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tracker?.end()
    }

    private func initViews() {
        self.view.addSubview(contentView)
        self.view.addSubview(bottomView)
        contentView.addSubview(cardTableView)
        contentView.addSubview(headerView)

        self.cardTableView.isScrollEnabled = false
        self.cardTableView.separatorStyle = .none
        self.cardTableView.rowHeight = UITableViewAutomaticDimension
        self.cardTableView.estimatedRowHeight = 250
        self.cardTableView.contentInset.top = 0
        self.cardTableView.contentInset.bottom = 0
        self.cardTableView.contentInsetAdjustmentBehavior = .never

        cardTableView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.view)
            make.bottom.equalTo(self.bottomView.snp.top)
        }

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }

        bottomView.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(self.view)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(cardTableView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: TableView
extension PlaceController: UITableViewDelegate, UITableViewDataSource {
    private func registerCards() {
        func register(_ cellClass: PlaceCardView.Type) {
            cellTypes[cellClass.cardId!] = cellClass
        }

        // Register Shimmer Cards
        register(PlaceShimmerImageBannerCard.self)
        register(PlaceShimmerNameTagCard.self)

        // Register Place Cards
        register(PlaceBasicImageBannerCard.self)
        register(PlaceBasicClosedCard.self)
        register(PlaceBasicNameTagCard.self)
        register(PlaceBasicAddressCard.self)
        register(PlaceBasicBusinessHourCard.self)

        // Register Location Cards
        register(PlaceHeaderLocationCard.self)
        register(PlaceBasicLocationCard.self)

        // Register Partner Content
        register(PlaceHeaderPartnerContentCard.self)
        register(PlacePartnerArticleCard.self)
        register(PlacePartnerInstagramCard.self)

        // Register Review Cards
        register(PlaceHeaderReviewCard.self)
//        register(PlaceVendorFacebookReviewCard.self)

        // Register Menu Cards
        register(PlaceHeaderMenuCard.self)
        register(PlaceVendorMenuImageCard.self)

        // Register About Cards
        register(PlaceHeaderAboutCard.self)
        register(PlaceBasicDescriptionCard.self)
        register(PlaceBasicPhoneCard.self)
        register(PlaceBasicPriceCard.self)
        register(PlaceBasicWebsiteCard.self)

        // Register Extended Loaded Cards
        // TODO Add back PlaceAward Card when ready
//        register(PlaceExtendedPlaceAwardCard.self)

        // Register Suggest Edit Cards
        register(PlaceSuggestEditCard.self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row]
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath.row] = cell.bounds.height
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        tableView.beginUpdates()
        cells[indexPath.row].didTap()
        tableView.endUpdates()
    }

    private func create(cards: [PlaceCard]) -> [PlaceCardView] {
        return cards.map { card in
            if let cell = cellTypes[card.cardId]?.init(card: card, controller: self) {
                return cell
            }
            return PlaceStaticEmptyCard(card: card, controller: self)
        } + [PlaceStaticLastCard(controller: self)]
    }
}

// MARK: Actions
extension PlaceController: UIGestureRecognizerDelegate, SFSafariViewControllerDelegate {
    enum ClickAction {
        case map
        case partnerInstagram
        case partnerArticle

        case addedToCollection

        case direction
        case call

        case screenshot
        case mapHeading
        case mapExternal

        case about
        case suggestEdit
        case menuWeb
        case hours
        case tag

        case partnerInstagramItem(Int)
        case partnerArticleItem(Int)
        case menuImageItem(Int)

        var name: String {
            switch self {
            case .map: return "click_map"
            case .partnerInstagram: return "click_partner_instagram"
            case .partnerArticle: return "click_partner_article"

            case .addedToCollection: return "click_added_to_collection"

            case .direction: return "click_direction"
            case .call: return "click_call"

            case .screenshot: return "click_screenshot"
            case .mapHeading: return "click_map_heading"
            case .mapExternal: return "click_map_external"

            case .about: return "click_about"
            case .suggestEdit: return "click_suggest_edit"
            case .menuWeb: return "click_menu_web"
            case .hours: return "click_hours"
            case .tag: return "click_tag"

            case .partnerInstagramItem(let count):
                return "click_partner_instagram_item(\(count))"
            case .partnerArticleItem(let count):
                return "click_partner_article_item(\(count))"
            case .menuImageItem(let count):
                return "click_menu_image_item(\(count))"
            }
        }
    }

    enum NavigationAction {
        case bannerImageItem(Int)
        case partnerInstagramItem(Int)
        case partnerArticleItem(Int)

        var name: String {
            switch self {
            case .bannerImageItem(let count):
                return "navigation_banner_image_item(\(count))"
            case .partnerInstagramItem(let count):
                return "navigation_partner_instagram_item(\(count))"
            case .partnerArticleItem(let count):
                return "navigation_partner_article_item(\(count))"
            }
        }
    }

    func apply(click: ClickAction) {
        tracker?.add(name: click.name)
        Analytics.logEvent("rip_action", parameters: [
            AnalyticsParameterItemID: "place-\(self.placeId)" as NSObject,
            AnalyticsParameterItemCategory: click.name as NSObject
        ])

        // TODO Actions Place Client Loaded Cards Migrations
        switch click {
        case .map:
            let controller = PlaceMapController(controller: self)
            self.navigationController?.pushViewController(controller, animated: true)

        case .partnerInstagram:
            let controller = PlacePartnerInstagramController(controller: self, medias: [], nextPlaceSort: nil)
            self.navigationController!.pushViewController(controller, animated: true)

        case .partnerArticle:
            let controller = PlacePartnerArticleController(controller: self, articles: [], nextPlaceSort: nil)
            self.navigationController!.pushViewController(controller, animated: true)

        case .suggestEdit: self.clickSuggestEdit()
        case .direction: self.clickDirection()
        case .call: self.clickCall()
        case .menuWeb: self.clickWebMenu()

        default:return
        }
    }

    func apply(navigation: NavigationAction) {
        DispatchQueue.main.async {
            self.tracker?.add(name: navigation.name)
            Analytics.logEvent("rip_navigation", parameters: [
                AnalyticsParameterItemID: "place-\(self.placeId)" as NSObject,
                AnalyticsParameterItemCategory: navigation.name as NSObject
            ])
        }
    }

    private func clickDirection() {
        if let address = place?.location.address?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            // Monster Jobs uses comgooglemap url scheme, those fuckers
            if (UIApplication.shared.canOpenURL(URL(string: "https://www.google.com/maps/")!)) {
                UIApplication.shared.open(URL(string: "https://www.google.com/maps/?daddr=\(address)")!)
            } else if (UIApplication.shared.canOpenURL(URL(string: "http://maps.apple.com/")!)) {
                UIApplication.shared.open(URL(string: "http://maps.apple.com/?daddr=\(address)")!)
            }
        }
    }

    private func clickCall() {
        if let phone = place?.phone?.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression, range: nil) {
            if let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }

    private func clickSuggestEdit() {
        Authentication.requireAuthentication(controller: self) { state in
            switch state {
            case .loggedIn:
                let urlComps = NSURLComponents(string: "https://airtable.com/shrfxcHiCwlSl1rjk")!
                urlComps.queryItems = [
                    URLQueryItem(name: "prefill_Place.id", value: self.placeId),
                    URLQueryItem(name: "prefill_Place.status", value: "Open"),
                    URLQueryItem(name: "prefill_Place.name", value: self.place?.name),
                    URLQueryItem(name: "prefill_Place.Location.address", value: self.place?.location.address)
                ]
                let safari = SFSafariViewController(url: urlComps.url!)
                safari.delegate = self
                self.present(safari, animated: true, completion: nil)
            default:
                return
            }
        }
    }

    private func clickWebMenu() {
        if let menuUrl = self.place?.menu?.url, let url = URL(string: menuUrl) {
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            self.present(safari, animated: true, completion: nil)
        }
    }

    @objc func handleScreenshot() {
        self.apply(click: .screenshot)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: Scrolling
extension PlaceController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateNavigationBackground(y: scrollView.contentOffset.y)
    }

    func updateNavigationBackground(y: CGFloat) {
        func updateTint(color: UIColor) {
            headerView.backButton.tintColor = color
            headerView.addButton.tintColor = color
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
        let y = self.cardTableView.contentOffset.y
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

fileprivate class PlaceBottomView: UIView {
    private let mainButton = UIButton()
    private let ratingPercentLabel = ReviewRatingLabel()
    private let ratingCountLabel = UILabel()
    private let openLabel: UIButton = {
        let button = UIButton()
        button.setTitle("Closed Now", for: .normal)
        button.setTitleColor(.primary700, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 11.0, weight: .medium)

        button.setImage(UIImage(named: "RIP-Bottom-Clock"), for: .normal)
        button.tintColor = .primary700
        button.imageEdgeInsets.left = -8.0

        button.backgroundColor = UIColor(hex: "eeeeee")
        button.layer.cornerRadius = 3.0
        button.contentEdgeInsets.left = 10
        button.contentEdgeInsets.right = 10
        return button
    }()

    var controller: PlaceController?
    var place: Place? {
        didSet {
            if let place = place {
                self.setHidden(isHidden: false)
                self.render(place: place)
            } else {
                self.setHidden(isHidden: true)
            }
        }
    }

    static let openStyle = Style("open", {
        $0.color = UIColor.secondary
    })
    static let closeStyle = Style("close", {
        $0.color = UIColor.primary
    })

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.initViews()
        self.setHidden(isHidden: true)
    }

    private func initViews() {
        self.backgroundColor = .white
        self.addSubview(ratingCountLabel)
        self.addSubview(ratingPercentLabel)
        self.addSubview(openLabel)
        self.addSubview(mainButton)

        mainButton.setTitle("ACTION", for: .normal)
        mainButton.setTitleColor(.white, for: .normal)
        mainButton.backgroundColor = .primary
        mainButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        mainButton.layer.cornerRadius = 3
        mainButton.layer.borderWidth = 1.0
        mainButton.layer.borderColor = UIColor.primary.cgColor
        mainButton.snp.makeConstraints { make in
            make.right.equalTo(self).inset(24)
            make.top.equalTo(self).inset(10)
            make.bottom.equalTo(self.safeArea.bottom).inset(10)
            make.height.equalTo(40)
        }

        ratingPercentLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self).inset(24)
            make.top.equalTo(self).inset(10)
        }

        ratingCountLabel.text = "0 Reviews"
        ratingCountLabel.font = UIFont.systemFont(ofSize: 11.0, weight: .regular)
        ratingCountLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        ratingCountLabel.textAlignment = .left
        ratingCountLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self).inset(12)
        }

        openLabel.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.bottom.equalTo(self.safeArea.bottom).inset(10)
            make.height.equalTo(20)
        }
    }

    private func setHidden(isHidden: Bool) {
        self.mainButton.isHidden = isHidden
        self.ratingPercentLabel.isHidden = isHidden
        self.ratingCountLabel.isHidden = isHidden
        self.openLabel.isHidden = isHidden
    }

    private func render(place: Place) {
        ratingCountLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self).inset(24)
        }

        switch place.hours.isOpen() {
        case .open:
            openLabel.tintColor = .secondary700
            openLabel.setTitleColor(.secondary700, for: .normal)
            openLabel.setTitle("Open Now", for: .normal)
        case .opening:
            openLabel.tintColor = .secondary700
            openLabel.setTitleColor(.secondary700, for: .normal)
            openLabel.setTitle("Opening Soon", for: .normal)
        case .closing:
            openLabel.tintColor = .primary700
            openLabel.setTitleColor(.primary700, for: .normal)
            openLabel.setTitle("Closing Soon", for: .normal)
        case .closed:
            openLabel.tintColor = .primary700
            openLabel.setTitleColor(.primary700, for: .normal)
            openLabel.setTitle("Closed Now", for: .normal)
        case .none:
            openLabel.tintColor = UIColor(hex: "222222")
            openLabel.setTitleColor(UIColor(hex: "222222"), for: .normal)
            openLabel.setTitle("No Opening Hours", for: .normal)
        }

        if place.phone != nil {
            mainButton.setTitle("CALL", for: .normal)
            mainButton.addTarget(self, action: #selector(actionCall(_:)), for: .touchUpInside)
            mainButton.snp.makeConstraints { make in
                make.width.equalTo(110)
            }
        } else if place.location.address != nil {
            mainButton.setTitle("DIRECTIONS", for: .normal)
            mainButton.addTarget(self, action: #selector(actionDirection(_:)), for: .touchUpInside)
            mainButton.snp.makeConstraints { make in
                make.width.equalTo(145)
            }
        }
    }

    @objc func actionCall(_ sender: Any) {
        self.controller?.apply(click: .call)
    }

    @objc func actionDirection(_ sender: Any) {
        self.controller?.apply(click: .direction)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: -2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PlaceHeaderView: UIView {
    private let toastStyle: ToastStyle = {
        var style = ToastStyle()
        style.backgroundColor = UIColor.bgTag
        style.cornerRadius = 5
        style.imageSize = CGSize(width: 20, height: 20)
        style.fadeDuration = 6.0
        style.messageColor = UIColor.black.withAlphaComponent(0.85)
        style.messageFont = UIFont.systemFont(ofSize: 15, weight: .regular)
        style.messageNumberOfLines = 2
        style.messageAlignment = .left

        return style
    }()

    fileprivate let backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "NavigationBar-Back"), for: .normal)
        button.tintColor = .white
        button.imageEdgeInsets.left = 18
        button.contentHorizontalAlignment = .left
        return button
    }()
    fileprivate let titleView: UILabel = {
        let titleView = UILabel()
        titleView.font = .systemFont(ofSize: 17, weight: .medium)
        titleView.textAlignment = .left
        titleView.textColor = .black
        return titleView
    }()
    fileprivate let addButton = PlaceAddButton()

    let backgroundView = UIView()
    let shadowView = UIView()

    var place: Place? {
        didSet {
            if let place = place {
                self.titleView.text = place.name
                self.addButton.place = place
            } else {
                self.titleView.text = nil
                self.addButton.place = nil
            }
        }
    }
    var controller: UIViewController

    init(controller: UIViewController, place: Place? = nil,
         tintColor: UIColor = UIColor.black, backgroundVisible: Bool = true, titleHidden: Bool = false) {
        self.controller = controller
        super.init(frame: CGRect.zero)
        self.initViews()

        self.titleView.isHidden = titleHidden
        self.addButton.tintColor = tintColor
        self.backButton.tintColor = tintColor
        self.titleView.textColor = tintColor

        self.backgroundView.backgroundColor = .white
        self.backgroundView.isHidden = !backgroundVisible
        self.shadowView.isHidden = !backgroundVisible

        self.backButton.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)

        self.place = place
        self.titleView.text = place?.name
        self.addButton.controller = controller
        self.addButton.place = place
    }

    private func initViews() {
        self.backgroundColor = .clear
        self.addSubview(shadowView)
        self.addSubview(backgroundView)
        self.addSubview(backButton)
        self.addSubview(titleView)

        self.addSubview(addButton)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.left.equalTo(self)
            make.bottom.equalTo(self)
            make.width.equalTo(56)
            make.height.equalTo(44)
        }

        addButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.right.equalTo(self).inset(18)
            make.bottom.equalTo(self)
            make.width.equalTo(30)
            make.height.equalTo(44)
        }

        titleView.snp.makeConstraints { make in
            make.top.bottom.equalTo(self.backButton)
            make.left.equalTo(backButton.snp.right)
            make.right.equalTo(addButton.snp.left)
        }

        backgroundView.backgroundColor = .clear
        backgroundView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        shadowView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    @objc func onBackButton(_ sender: Any) {
        self.controller.navigationController?.popViewController(animated: true)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shadowView.shadow(vertical: 2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PlaceAddButton: UIButton {
    private let toastStyle: ToastStyle = {
        var style = ToastStyle()
        style.backgroundColor = UIColor.bgTag
        style.cornerRadius = 5
        style.imageSize = CGSize(width: 20, height: 20)
        style.fadeDuration = 6.0
        style.messageColor = UIColor.black.withAlphaComponent(0.85)
        style.messageFont = UIFont.systemFont(ofSize: 15, weight: .regular)
        style.messageNumberOfLines = 2
        style.messageAlignment = .left

        return style
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.setImage(UIImage(named: "RIP-Add"), for: .normal)
        self.tintColor = .white

        self.addTarget(self, action: #selector(onButton(_:)), for: .touchUpInside)
    }

    var controller: UIViewController?
    var place: Place?

    @objc func onButton(_ button: Any) {
        guard let controller = self.controller, let place = self.place else {
            return
        }

        Authentication.requireAuthentication(controller: controller) { state in
            switch state {
            case .loggedIn:
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                let controller = AddToCollectionController(place: place) { action in
                    switch action {
                    case .add(let collection):
                        if let placeController = self.controller as? PlaceController {
                            placeController.apply(click: .addedToCollection)
                        }
                        self.controller?.makeToast("Added to \(collection.name)", image: .checkmark)

                    case .remove(let collection):
                        self.controller?.makeToast("Removed from \(collection.name)", image: .checkmark)

                    default:
                        return
                    }

                }
                self.controller?.present(controller, animated: true)
            default:
                return
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}