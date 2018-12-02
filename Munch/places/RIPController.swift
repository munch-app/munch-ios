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

    var tracker: UserPlaceActivityTracker?

    let provider = MunchProvider<PlaceService>()
    let disposeBag = DisposeBag()

    private var cells = [RIPCell]()

    fileprivate let tableView = UITableView()
    fileprivate var headerView = RIPHeaderView(tintColor: .white, backgroundVisible: false)
    fileprivate let bottomView = RIPBottomView()

    fileprivate let contentView = UIView()

    init(placeId: String) {
        self.placeId = placeId
        Crashlytics.sharedInstance().setObjectValue(placeId, forKey: "RIPController.placeId")

        super.init(nibName: nil, bundle: nil)

        // Might want to change this around for different pushing controller
        self.hidesBottomBarWhenPushed = true
        self.cells = [RIPLoadingImageCell.create(controller: self), RIPLoadingNameCell.create(controller: self)]
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
        self.initViews()

        // Register Delegate
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.headerView.controller = self
        self.headerView.backButton.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)

        self.provider.rx.request(.get(self.placeId))
                .map { res throws -> (PlaceData) in
                    return try res.map(data: PlaceData.self)
                }.subscribe { event in
                    switch event {
                    case .success(let data):
                        RecentPlaceDatabase().add(id: self.placeId, data: data.place)

                        self.data = data
                        self.tracker = UserPlaceActivityTracker(place: data.place)

                        self.headerView.place = data.place
                        self.bottomView.place = data.place

                        self.cells = self.tableView(cellsForData: data)
                        self.tableView.isScrollEnabled = true
                        self.tableView.reloadData()
                        self.scrollViewDidScroll(self.tableView)

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
        contentView.addSubview(tableView)
        contentView.addSubview(headerView)

        self.tableView.isScrollEnabled = false
        self.tableView.separatorStyle = .none
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 250
        self.tableView.contentInset.top = 0
        self.tableView.contentInset.bottom = 0
        self.tableView.contentInsetAdjustmentBehavior = .never

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }

        bottomView.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(self.view)
        }

        tableView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.view)
            make.bottom.equalTo(self.bottomView.snp.top)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(tableView)
        }
    }

    @objc func onBackButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: TableView
extension RIPController: UITableViewDelegate, UITableViewDataSource {
    func tableView(cellsForData data: PlaceData) -> [RIPCell] {
        var cells = [RIPCell]()

        func appendTo(type: RIPCell.Type) {
            if type.isAvailable(data: data) {
                cells.append(type.create(controller: self))
            }
        }

        appendTo(type: RIPImageBannerCell.self)
        appendTo(type: RIPTitleCell.self)
        appendTo(type: RIPClosedCell.self)
        return cells
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row]
    }

//    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return cellHeights[indexPath.row]
//    }
//
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? RIPCell {
            cell.willDisplay(data: data)
        }
    }
}

// MARK: Actions
extension RIPController: UIGestureRecognizerDelegate, SFSafariViewControllerDelegate {
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
        case award(String)

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

            case .award(let collectionId):
                return "click_award(\(collectionId)"
            }
        }
    }

    func apply(click: ClickAction) {
        tracker?.add(name: click.name)
        Analytics.logEvent("rip_action", parameters: [
            AnalyticsParameterItemID: "place-\(self.placeId)" as NSObject,
            AnalyticsParameterItemCategory: click.name as NSObject
        ])

        switch click {
//        case .map:
//            let controller = PlaceMapController(controller: self)
//            self.navigationController?.pushViewController(controller, animated: true)
//
//        case .partnerInstagram:
//            let controller = PlacePartnerInstagramController(controller: self, medias: [], nextPlaceSort: nil)
//            self.navigationController!.pushViewController(controller, animated: true)
//
//        case .partnerArticle:
//            let controller = PlacePartnerArticleController(controller: self, articles: [], nextPlaceSort: nil)
//            self.navigationController!.pushViewController(controller, animated: true)
//
//        case .award(let collectionId):
//            let controller = UserPlaceCollectionController(collectionId: collectionId)
//            self.navigationController?.pushViewController(controller, animated: true)
//
//        case .suggestEdit: self.clickSuggestEdit()
//        case .direction: self.clickDirection()
//        case .call: self.clickCall()
//        case .menuWeb: self.clickWebMenu()

        default:
            return
        }
    }

    private func clickDirection() {
        if let address = data.place.location.address?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            // Monster Jobs uses comgooglemap url scheme, those fuckers
            if (UIApplication.shared.canOpenURL(URL(string: "https://www.google.com/maps/")!)) {
                UIApplication.shared.open(URL(string: "https://www.google.com/maps/?daddr=\(address)")!)
            } else if (UIApplication.shared.canOpenURL(URL(string: "http://maps.apple.com/")!)) {
                UIApplication.shared.open(URL(string: "http://maps.apple.com/?daddr=\(address)")!)
            }
        }
    }

    private func clickCall() {
        if let phone = data.place.phone?.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression, range: nil) {
            if let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }

    private func clickSuggestEdit() {
//        Authentication.requireAuthentication(controller: self) { state in
//            switch state {
//            case .loggedIn:
//                let urlComps = NSURLComponents(string: "https://airtable.com/shrfxcHiCwlSl1rjk")!
//                urlComps.queryItems = [
//                    URLQueryItem(name: "prefill_Place.id", value: self.placeId),
//                    URLQueryItem(name: "prefill_Place.status", value: "Open"),
//                    URLQueryItem(name: "prefill_Place.name", value: self.place?.name),
//                    URLQueryItem(name: "prefill_Place.Location.address", value: self.place?.location.address)
//                ]
//                let safari = SFSafariViewController(url: urlComps.url!)
//                safari.delegate = self
//                self.present(safari, animated: true, completion: nil)
//            default:
//                return
//            }
//        }
    }

    private func clickWebMenu() {
        if let menuUrl = self.data.place.menu?.url, let url = URL(string: menuUrl) {
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            self.present(safari, animated: true, completion: nil)
        }
    }

    @objc func handleScreenshot() {
        self.apply(click: .screenshot)
    }
}

// MARK: Scrolling
extension RIPController {
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
        let y = self.tableView.contentOffset.y
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

class RIPHeaderView: UIView {
    let backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "NavigationBar-Back"), for: .normal)
        button.tintColor = .white
        button.imageEdgeInsets.left = 18
        button.contentHorizontalAlignment = .left
        return button
    }()
    let titleView: UILabel = {
        let titleView = UILabel()
        titleView.font = .systemFont(ofSize: 17, weight: .medium)
        titleView.textAlignment = .left
        titleView.textColor = .black
        return titleView
    }()

    let backgroundView = UIView()
    let shadowView = UIView()

    var place: Place? {
        didSet {
            if let place = place {
                self.titleView.text = place.name
            } else {
                self.titleView.text = nil
            }
        }
    }
    override var tintColor: UIColor! {
        didSet  {
            self.backButton.tintColor = tintColor
            self.titleView.textColor = tintColor
        }
    }

    var controller: UIViewController!

    init(tintColor: UIColor = .black, backgroundVisible: Bool = true, titleHidden: Bool = false) {
        super.init(frame: CGRect.zero)
        self.initViews()

        self.titleView.isHidden = titleHidden
        self.tintColor = tintColor

        self.backgroundView.backgroundColor = .white
        self.backgroundView.isHidden = !backgroundVisible
        self.shadowView.isHidden = !backgroundVisible
    }

    private func initViews() {
        self.backgroundColor = .clear
        self.backgroundView.backgroundColor = .clear

        self.addSubview(shadowView)
        self.addSubview(backgroundView)
        self.addSubview(backButton)
        self.addSubview(titleView)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.left.bottom.equalTo(self)

            make.width.equalTo(56)
            make.height.equalTo(44)
        }

        titleView.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self.backButton)
            maker.left.equalTo(backButton.snp.right)
            maker.right.equalTo(self).inset(56)
        }

        backgroundView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        shadowView.snp.makeConstraints { make in
            make.edges.equalTo(self)
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

class RIPBottomView: UIView {
    var controller: RIPController?
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

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.initViews()
        self.setHidden(isHidden: true)
    }

    private func initViews() {
        self.backgroundColor = .white
    }

    private func setHidden(isHidden: Bool) {

    }

    private func render(place: Place) {

    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: -2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
