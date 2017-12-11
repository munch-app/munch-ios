//
//  PlaceController.swift
//  Munch
//
//  Created by Fuxing Loh on 8/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import Cosmos
import SwiftRichString

class PlaceViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    let placeId: String
    var place: Place?

    private var cards = [PlaceShimmerImageBannerCard.card, PlaceShimmerNameTagCard.card]
    private var cells = [PlaceCardView]()
    private var cellTypes = [String: PlaceCardView.Type]()

    private let cardTableView = UITableView()
    private let headerView = PlaceHeaderView()
    private let bottomView = PlaceBottomView()

    init(placeId: String) {
        self.placeId = placeId
        super.init(nibName: nil, bundle: nil)

        self.hidesBottomBarWhenPushed = true
        self.cells = [PlaceShimmerImageBannerCard.create(controller: self), PlaceShimmerNameTagCard.create(controller: self)]
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
        self.registerCards()
        self.initViews()

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        self.cardTableView.delegate = self
        self.cardTableView.dataSource = self
        self.headerView.backButton.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)

        MunchApi.places.cards(id: placeId) { meta, place, cards in
            if let place = place, meta.isOk() {
                self.cards = cards
                self.place = place
                self.bottomView.render(place: place)

                self.cells = self.create(cards: cards)
                self.cardTableView.isScrollEnabled = true
                self.cardTableView.reloadData()
                self.scrollViewDidScroll(self.cardTableView)
            } else {
                self.present(meta.createAlert(), animated: true)
            }
        }
    }

    private func initViews() {
        self.view.addSubview(cardTableView)
        self.view.addSubview(headerView)
        self.view.addSubview(bottomView)

        self.cardTableView.isScrollEnabled = false
        self.cardTableView.separatorStyle = .none
        self.cardTableView.rowHeight = UITableViewAutomaticDimension
        self.cardTableView.estimatedRowHeight = 1000
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
    }

    @objc func onBackButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class PlaceHeaderView: UIView {
    let backButton = UIButton()
    let backgroundView = UIView()
    let shadowView = UIView()

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.initViews()
    }

    private func initViews() {
        self.backgroundColor = .clear
        self.addSubview(shadowView)
        self.addSubview(backgroundView)
        self.addSubview(backButton)

        backButton.setImage(UIImage(named: "NavigationBar-Back"), for: .normal)
        backButton.tintColor = .white
        backButton.imageEdgeInsets.left = 18
        backButton.contentHorizontalAlignment = .left
        backButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.left.equalTo(self)
            make.bottom.equalTo(self)
            make.width.equalTo(64)
            make.height.equalTo(44)
        }

        backgroundView.backgroundColor = .clear
        backgroundView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        shadowView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shadowView.hairlineShadow(height: 1.0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class PlaceBottomView: UIView {
    let mainButton = UIButton()
    let ratingPercentLabel = UILabel()
    let ratingCountLabel = UILabel()
    let openingHours = UILabel()

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
        self.addSubview(openingHours)
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

        ratingPercentLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .semibold)
        ratingPercentLabel.textColor = .primary300
        ratingPercentLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self).inset(24)
            make.top.equalTo(self).inset(10)
        }

        ratingCountLabel.text = "0 Reviews"
        ratingCountLabel.font = UIFont.systemFont(ofSize: 11.0, weight: .regular)
        ratingCountLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        ratingCountLabel.textAlignment = .left
        ratingCountLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self).inset(13)
        }

        openingHours.text = "No Opening Hour"
        openingHours.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
        openingHours.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.right.equalTo(mainButton.snp.left).inset(-12)
            make.bottom.equalTo(self.safeArea.bottom).inset(10)
            make.height.equalTo(20)
        }
    }

    private func setHidden(isHidden: Bool) {
        self.mainButton.isHidden = isHidden
        self.ratingPercentLabel.isHidden = isHidden
        self.ratingCountLabel.isHidden = isHidden
        self.openingHours.isHidden = isHidden
    }

    func render(place: Place) {
        self.setHidden(isHidden: false)
        self.place = place

        if let text = ReviewRatingUtils.create(review: place.review) {
            self.ratingPercentLabel.attributedText = text
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
            let businessHours = BusinessHour(hours: hours)
            openingHours.text = businessHours.todayTime
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
        if let phone = place?.phone {
            if let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }

    @objc func actionDirection(_ sender: Any) {
        if let address = place?.location.address?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
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
        self.hairlineShadow(height: -1.0)
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
        register(PlaceBasicNameTagCard.self)
        register(PlaceBasicImageBannerCard.self)
        register(PlaceBasicAddressCard.self)
        register(PlaceBasicBusinessHourCard.self)

        // Register Location Cards
        register(PlaceHeaderLocationCard.self)
        register(PlaceBasicLocationCard.self)

        // Register Vendor Article Cards
        register(PlaceHeaderArticleCard.self)
        register(PlaceVendorArticleGridCard.self)

        // Register Vendor Instagram Cards
        register(PlaceHeaderInstagramCard.self)
        register(PlaceVendorInstagramGridCard.self)

        // Register Review Cards
        register(PlaceHeaderReviewCard.self)
        register(PlaceVendorFacebookReviewCard.self)

        // Register About Cards
        register(PlaceHeaderAboutCard.self)
        register(PlaceBasicDescriptionCard.self)
        register(PlaceBasicPhoneCard.self)
        register(PlaceBasicWebsiteCard.self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cards.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row]
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
        }
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
        // Starts from - 20
        if (y < -36.0) {
            // -20 is the status bar height, another -16 is the height where it update the status bar color
            headerView.backButton.tintColor = .black
            headerView.backgroundView.isHidden = true
            headerView.shadowView.isHidden = true
        } else if (155 > y) {
            // Full Opacity
            headerView.backButton.tintColor = .white
            headerView.backgroundView.isHidden = true
            headerView.shadowView.isHidden = true
        } else if (175 < y) {
            // Full White
            headerView.backButton.tintColor = .black
            headerView.backgroundView.isHidden = false
            headerView.backgroundView.backgroundColor = .white
            headerView.shadowView.isHidden = false
        } else {
            let progress = 1.0 - (175 - y) / 20.0
            headerView.backButton.tintColor = progress > 0.5 ? .black : .white
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
    static let min: (CGFloat, CGFloat, CGFloat) = (1.0, 0.33, 0.22)
    static let max: (CGFloat, CGFloat, CGFloat) = (0.02, 0.57, 0.32)

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

    class func color(percent: CGFloat) -> UIColor {
        let red = min.0 + (max.0 - min.0) * percent
        let green = min.1 + (max.1 - min.1) * percent
        let blue = min.2 + (max.2 - min.2) * percent

        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}