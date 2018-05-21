//
//  PlaceController.swift
//  Munch
//
//  Created by Fuxing Loh on 8/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

import SnapKit
import Firebase
import Crashlytics
import SwiftRichString

import Cosmos
import Toast_Swift

class PlaceViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, SFSafariViewControllerDelegate {
    let placeId: String
    var place: Place?
    var liked: Bool?

    private var cards = [PlaceShimmerImageBannerCard.card, PlaceShimmerNameTagCard.card]
    private var cells = [PlaceCardView]()
    private var cellTypes = [String: PlaceCardView.Type]()
    private var cellHeights = [CGFloat](repeating: UITableViewAutomaticDimension, count: 100)

    fileprivate let cardTableView = UITableView()
    fileprivate var headerView: PlaceHeaderView!
    fileprivate let bottomView = PlaceBottomView()

    fileprivate let contentView = UIView()

    init(placeId: String) {
        self.placeId = placeId
        Crashlytics.sharedInstance().setObjectValue(placeId, forKey: "PlaceViewController.placeId")
        super.init(nibName: nil, bundle: nil)

        self.headerView = PlaceHeaderView(controller: self, tintColor: .white, backgroundVisible: false, titleHidden: true)
        self.hidesBottomBarWhenPushed = true
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

    @objc func handleScreenshot() {
        Analytics.logEvent(AnalyticsEventShare, parameters: [
            AnalyticsParameterItemID: "place-\(self.placeId)" as NSObject,
            AnalyticsParameterContentType: "screenshot" as NSObject
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCards()
        self.initViews()

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        self.cardTableView.delegate = self
        self.cardTableView.dataSource = self

        MunchApi.places.cards(id: placeId) { meta, place, cards, liked in
            if let place = place, meta.isOk() {
                self.cards = cards
                self.place = place
                self.liked = liked
                self.headerView.render(place: place, liked: liked)
                self.bottomView.render(place: place)

                self.cells = self.create(cards: cards)
                self.cardTableView.isScrollEnabled = true
                self.cardTableView.reloadData()
                self.scrollViewDidScroll(self.cardTableView)

                MunchApi.collections.recent.put(placeId: self.placeId) { meta in
                    let recentDatabase = RecentDatabase(name: "RecentlyViewedPlace", maxItems: 20)
                    recentDatabase.put(text: self.placeId, dictionary: place.toParams())
                }
            } else {
                self.present(meta.createAlert(), animated: true)
            }
        }
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

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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
    fileprivate let heartButton = HeartButton()
    fileprivate let addButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "RIP-Add"), for: .normal)
        button.tintColor = .white
        return button
    }()

    let backgroundView = UIView()
    let shadowView = UIView()

    var place: Place?
    var placeId: String?
    var liked: Bool?
    var controller: UIViewController

    init(controller: UIViewController, place: Place? = nil, liked: Bool? = nil,
         tintColor: UIColor = UIColor.black, backgroundVisible: Bool = true, titleHidden: Bool = false) {
        self.controller = controller
        super.init(frame: CGRect.zero)
        self.initViews()

        self.titleView.isHidden = titleHidden
        self.addButton.tintColor = tintColor
        self.heartButton.tintColor = tintColor
        self.backButton.tintColor = tintColor
        self.titleView.textColor = tintColor

        self.backgroundView.isHidden = !backgroundVisible
        self.shadowView.isHidden = !backgroundVisible
        if backgroundVisible {
            self.backgroundView.backgroundColor = .white
        }

        self.backButton.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)
        self.addButton.addTarget(self, action: #selector(onAddButton(_:)), for: .touchUpInside)

        if let place = place {
            render(place: place, liked: liked)
        }
    }

    private func initViews() {
        self.backgroundColor = .clear
        self.addSubview(shadowView)
        self.addSubview(backgroundView)
        self.addSubview(backButton)
        self.addSubview(titleView)

        self.addSubview(heartButton)
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

        heartButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.right.equalTo(addButton.snp.left).inset(-10)
            make.bottom.equalTo(self)
            make.width.equalTo(30)
            make.height.equalTo(44)
        }

        titleView.snp.makeConstraints { make in
            make.top.bottom.equalTo(self.backButton)
            make.left.equalTo(backButton.snp.right)
            make.right.equalTo(heartButton.snp.left)
        }

        backgroundView.backgroundColor = .clear
        backgroundView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        shadowView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    func render(place: Place, liked: Bool?) {
        self.titleView.text = place.name
        self.place = place
        self.placeId = place.id
        self.liked = liked

        if let placeId = place.id, let name = place.name {
            self.heartButton.controller = controller
            self.heartButton.set(placeId: placeId, placeName: name, liked: liked ?? false)
        }
    }

    @objc func onBackButton(_ sender: Any) {
        self.controller.navigationController?.popViewController(animated: true)
    }

    @objc func onAddButton(_ sender: Any) {
        if let placeId = self.placeId {
            Authentication.requireAuthentication(controller: controller) { state in
                switch state {
                case .loggedIn:
                    let controller = CollectionSelectRootController(placeId: placeId) { placeCollection in
                        if let collection = placeCollection, let name = collection.name, let placeName = self.place?.name {
                            if let controller = self.controller as? PlaceViewController {
                                controller.contentView.makeToast("Added \(placeName) to '\(name)' collection.", image: UIImage(named: "RIP-Toast-Checkmark"), style: self.toastStyle)
                            } else {
                                self.controller.view.makeToast("Added \(placeName) to '\(name)' collection.", image: UIImage(named: "RIP-Toast-Checkmark"), style: self.toastStyle)
                            }

                        }

                        Analytics.logEvent("rip_action", parameters: [
                            AnalyticsParameterItemCategory: "click_add_collection" as NSObject
                        ])
                    }
                    self.controller.present(controller, animated: true)
                default:
                    return
                }
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shadowView.shadow(vertical: 2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    var place: Place?

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

    func render(place: Place) {
        self.setHidden(isHidden: false)
        self.place = place

        if let average = place.review?.average {
            self.ratingPercentLabel.render(average: average)

            self.ratingCountLabel.text = "\(place.review?.total ?? 0) Reviews"

            ratingCountLabel.snp.makeConstraints { (make) in
                make.left.equalTo(ratingPercentLabel.snp.right).inset(-5)
            }
        } else {
            // No Review
            ratingCountLabel.snp.makeConstraints { (make) in
                make.left.equalTo(self).inset(24)
            }
        }

        if let hours = place.hours, !hours.isEmpty {
            switch BusinessHour(hours: hours).isOpen() {
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
            case .closed:fallthrough
            case .none:
                openLabel.tintColor = .primary700
                openLabel.setTitleColor(.primary700, for: .normal)
                openLabel.setTitle("Closed Now", for: .normal)
            }
        } else {
            // No Opening Hour
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
        if let phone = place?.phone?.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression, range: nil) {
            if let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
                Analytics.logEvent("rip_action", parameters: [
                    AnalyticsParameterItemID: "place-\(self.place?.id ?? "")" as NSObject,
                    AnalyticsParameterItemCategory: "click_call" as NSObject
                ])

                UIApplication.shared.open(url)
            }
        }
    }

    @objc func actionDirection(_ sender: Any) {
        if let address = place?.location.address?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            Analytics.logEvent("rip_action", parameters: [
                AnalyticsParameterItemID: "place-\(self.place?.id ?? "")" as NSObject,
                AnalyticsParameterItemCategory: "click_direction" as NSObject
            ])

            // Monster Jobs uses comgooglemap url scheme, those fuckers
            if (UIApplication.shared.canOpenURL(URL(string: "https://www.google.com/maps/")!)) {
                UIApplication.shared.open(URL(string: "https://www.google.com/maps/?daddr=\(address)")!)
            } else if (UIApplication.shared.canOpenURL(URL(string: "http://maps.apple.com/")!)) {
                UIApplication.shared.open(URL(string: "http://maps.apple.com/?daddr=\(address)")!)
            }
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

/**
 Card TableView & Rendering
 */
extension PlaceViewController {
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
        register(PlaceVendorFacebookReviewCard.self)

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
        register(PlaceExtendedPlaceAwardCard.self)

        // Register Suggest Edit Cards
        register(PlaceSuggestEditCard.self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }

    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row]
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
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

/**
 Scroll handler
 With effect to the background
 */
extension PlaceViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateNavigationBackground(y: scrollView.contentOffset.y)
    }

    func updateNavigationBackground(y: CGFloat) {
        func updateTint(color: UIColor) {
            headerView.backButton.tintColor = color
            headerView.heartButton.tintColor = color
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

class ReviewRatingUtils {
    static let min: (CGFloat, CGFloat, CGFloat) = (1.0, 0.0, 0.0)
    static let med: (CGFloat, CGFloat, CGFloat) = (0.90, 0.40, 0.0)
    static let max: (CGFloat, CGFloat, CGFloat) = (0.00, 0.77, 0.0)

    class func create(review: Place.Review?) -> NSAttributedString? {
        if let percent = review?.average {
            return create(percent: CGFloat(percent))
        }
        return nil
    }

    class func create(percent: CGFloat, fontSize: CGFloat = 14.0) -> NSAttributedString {
        let fixedPercent: CGFloat = percent > 1.0 ? 1.0 : percent

        return "\(Int(fixedPercent * 100))%".set(style: .default { make in
            make.font = FontAttribute(font: UIFont.systemFont(ofSize: fontSize, weight: .semibold))
            make.color = color(percent: fixedPercent)
        })
    }

    class func text(percent: CGFloat) -> String {
        let fixedPercent: CGFloat = percent > 1.0 ? 1.0 : percent
        return String(format: "%.1f", fixedPercent * 10)
    }

    class func width(percent: CGFloat, fontSize: CGFloat = 14.0) -> CGFloat {
        let string = create(percent: percent, fontSize: fontSize).string
        let font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        return UILabel.textWidth(font: font, text: string)
    }

    class func color(percent: CGFloat) -> UIColor {
        let range = percent < 0.6 ? (min, med) : (med, max)
        let red = range.0.0 + (range.1.0 - range.0.0) * percent
        let green = range.0.1 + (range.1.1 - range.0.1) * percent
        let blue = range.0.2 + (range.1.2 - range.0.2) * percent

        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

class ReviewRatingLabel: UIButton {
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        self.setTitleColor(.white, for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 11.0, weight: .semibold)

        self.contentEdgeInsets = UIEdgeInsets.init(top: 2, left: 6, bottom: 2, right: 6)
        self.layer.cornerRadius = 3.0
    }

    func render(average: Double) {
        let float = CGFloat(average)
        let color = ReviewRatingUtils.color(percent: float)
        let text = ReviewRatingUtils.text(percent: float)

        self.setTitle(text, for: .normal)
        self.backgroundColor = color
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class HeartButton: UIButton {
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
        self.setImage(UIImage(named: "RIP-Heart"), for: .normal)
        self.tintColor = .white

        self.addTarget(self, action: #selector(onHeartButton(_:)), for: .touchUpInside)
    }

    var controller: UIViewController?

    private(set) var placeName: String?
    private(set) var placeId: String?
    private(set) var liked: Bool = false {
        didSet {
            if self.liked {
                self.setImage(UIImage(named: "RIP-Heart-Filled"), for: .normal)
            } else {
                self.setImage(UIImage(named: "RIP-Heart"), for: .normal)
            }
        }
    }

    public func set(placeId: String, placeName: String, liked: Bool) {
        self.placeName = placeName
        self.placeId = placeId
        self.liked = LikedPlaceManager.instance.isLiked(placeId: placeId, defaultLike: liked)
    }

    @objc func onHeartButton(_ button: Any) {
        if let controller = self.controller {
            Authentication.requireAuthentication(controller: controller) { state in
                switch state {
                case .loggedIn:
                    if let placeId = self.placeId {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()

                        self.liked = LikedPlaceManager.instance.push(placeId: placeId, liked: !self.liked)

                        if self.liked {
                            MunchApi.collections.liked.put(placeId: placeId) { meta in
                                guard meta.isOk() else {
                                    self.controller?.present(meta.createAlert(), animated: true)
                                    return
                                }

                                if let placeName = self.placeName {
                                    if let controller = self.controller as? PlaceViewController {
                                        controller.contentView.makeToast("Liked \(placeName)", image: UIImage(named: "RIP-Toast-Heart"), style: self.toastStyle)
                                    } else {
                                        self.controller?.view.makeToast("Liked \(placeName)", image: UIImage(named: "RIP-Toast-Heart"), style: self.toastStyle)
                                    }
                                }
                            }
                        } else {
                            MunchApi.collections.liked.delete(placeId: placeId) { meta in
                                guard meta.isOk() else {
                                    self.controller?.present(meta.createAlert(), animated: true)
                                    return
                                }

                                if let placeName = self.placeName {
                                    if let controller = self.controller as? PlaceViewController {
                                        controller.contentView.makeToast("Unliked \(placeName)", image: UIImage(named: "RIP-Toast-Close"), style: self.toastStyle)
                                    } else {
                                        self.controller?.view.makeToast("Unliked \(placeName)", image: UIImage(named: "RIP-Toast-Close"), style: self.toastStyle)
                                    }
                                }
                            }
                        }

                        Analytics.logEvent("rip_action", parameters: [
                            AnalyticsParameterItemCategory: "click_like" as NSObject
                        ])
                    }
                default:
                    return
                }
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}