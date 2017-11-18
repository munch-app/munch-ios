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
    var cards = [PlaceShimmerImageBannerCard.card, PlaceShimmerNameTagCard.card]

    private var cells = [Int: PlaceCardView]()
    private var cellTypes = [String: PlaceCardView.Type]()

    private let cardTableView = UITableView()
    private let headerView = PlaceHeaderView()
    private let bottomView = PlaceBottomView()

    init(placeId: String) {
        self.placeId = placeId
        super.init(nibName: nil, bundle: nil)

        self.hidesBottomBarWhenPushed = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCards()
        self.initViews()

        self.cardTableView.delegate = self
        self.cardTableView.dataSource = self
        self.headerView.backButton.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)

        MunchApi.places.cards(id: placeId) { meta, place, cards in
            if (meta.isOk()) {
                self.place = place
                self.cards = cards
                if let place = place {
                    self.bottomView.render(place: place)
                }

                self.cells.removeAll()
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

        self.cardTableView.separatorStyle = .none
        self.cardTableView.rowHeight = UITableViewAutomaticDimension
        self.cardTableView.estimatedRowHeight = 50
        self.cardTableView.contentInset.top = 0
        self.cardTableView.contentInset.bottom = 0

        cardTableView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.view).inset(-20)
            make.bottom.equalTo(self.bottomView.snp.top)
        }

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(64)
        }

        bottomView.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(self.view)
            make.height.equalTo(60)
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

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.initViews()
    }

    private func initViews() {
        self.backgroundColor = .clear
        self.addSubview(backgroundView)
        self.addSubview(backButton)

        backButton.setImage(UIImage(named: "Back-34"), for: .normal)
        backButton.tintColor = .white
        backButton.imageEdgeInsets.left = 18
        backButton.contentHorizontalAlignment = .left
        backButton.snp.makeConstraints { make in
            make.top.equalTo(self).inset(20)
            make.left.equalTo(self)
            make.bottom.equalTo(self)
            make.width.equalTo(64)
        }

        backgroundView.backgroundColor = .clear
        backgroundView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.hairlineShadow(height: 1.0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class PlaceBottomView: UIView {
    let mainButton = UIButton()
    let ratingView = CosmosView()
    let ratingLabel = UILabel()
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
        self.addSubview(ratingView)
        self.addSubview(ratingLabel)
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
            make.top.bottom.equalTo(self).inset(10)
        }

        ratingView.rating = 0
        ratingView.isUserInteractionEnabled = false
        ratingView.settings.fillMode = .precise
        ratingView.settings.filledColor = UIColor.secondary200
        ratingView.settings.filledBorderColor = UIColor.secondary200
        ratingView.settings.emptyColor = UIColor.clear
        ratingView.settings.emptyBorderColor = UIColor.secondary200
        ratingView.settings.starSize = 18
        ratingView.settings.starMargin = 0
        ratingView.snp.makeConstraints { (make) in
            make.left.equalTo(self).inset(23)
            make.top.equalTo(self).inset(10)
            make.width.equalTo(87)
            make.height.equalTo(20)
        }

        ratingLabel.text = "0 Reviews"
        ratingLabel.font = UIFont.systemFont(ofSize: 11.0, weight: .regular)
        ratingLabel.textColor = UIColor.black.withAlphaComponent(0.75)
        ratingLabel.textAlignment = .left
        ratingLabel.snp.makeConstraints { (make) in
            make.left.equalTo(ratingView.snp.right).inset(-10)
            make.right.equalTo(mainButton.snp.left).inset(-12)
            make.top.equalTo(self).inset(12)
        }

        openingHours.text = "No Opening Hour"
        openingHours.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
        openingHours.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.right.equalTo(mainButton.snp.left).inset(-12)
            make.bottom.equalTo(self).inset(10)
            make.height.equalTo(20)
        }
    }

    private func setHidden(isHidden: Bool) {
        self.mainButton.isHidden = isHidden
        self.ratingView.isHidden = isHidden
        self.ratingLabel.isHidden = isHidden
        self.openingHours.isHidden = isHidden
    }

    func render(place: Place) {
        self.setHidden(isHidden: false)
        self.place = place
        self.ratingView.rating = place.review.average
        self.ratingLabel.text = "\(place.review.total) Reviews"

        if let hours = place.hours {
            let businessHours = BusinessHour(hours: hours)
            if businessHours.isOpen() {
                openingHours.attributedText = "Open: ".set(style: PlaceBottomView.openStyle) + businessHours.todayTime
            } else {
                openingHours.attributedText = "Closed Now".set(style: PlaceBottomView.closeStyle)
            }
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
        let card = cards[indexPath.row]

        if let cell = cells[indexPath.row] {
            return cell
        } else {
            let cell = cellTypes[card.cardId]?.init(card: card, controller: self) ?? PlaceStaticEmptyCard(card: card, controller: self)
            cells[indexPath.row] = cell
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let cell = cells[indexPath.row] {
            tableView.beginUpdates()
            cell.didTap()
            tableView.endUpdates()
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
        // Stars from - 20
        if (155 > y) {
            // Full Opacity
            // -20 is the status bar height, another -16 is the height where it update the status bar color
            headerView.backgroundView.isHidden = true
            headerView.backButton.tintColor = y < -36.0 ? .black : .white
        } else if (175 < y) {
            // Full White
            headerView.backgroundView.isHidden = false
            headerView.backgroundView.backgroundColor = .white
            headerView.backButton.tintColor = .black
        } else {
            let progress = 1.0 - (175 - y) / 20.0
            headerView.backgroundView.isHidden = false
            headerView.backgroundView.backgroundColor = UIColor.white.withAlphaComponent(progress)
            headerView.backButton.tintColor = progress > 0.5 ? .black : .white
        }
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        // LightContent is white, Default is Black
        // See updateNavigationBackground for reference
        let y = self.cardTableView.contentOffset.y
        if (155 > y) {
            return y < -36.0 ? .default : .lightContent
        } else if (175 < y) {
            return .default
        } else {
            let progress = (1.0 - (175 - y) / 20.0)
            return progress > 0.5 ? .default : .lightContent
        }
    }
}


