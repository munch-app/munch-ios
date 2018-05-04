//
// Created by Fuxing Loh on 8/1/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

import SnapKit
import SwiftRichString
import NVActivityIndicatorView
import FirebaseAnalytics

class PlacePartnerArticleController: UIViewController, UIGestureRecognizerDelegate {
    let place: Place

    fileprivate var cachedHeight = [Int: CGFloat]()

    fileprivate var articles: [Article] = []
    fileprivate var nextMaxSort: String? = nil

    fileprivate let tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.allowsSelection = true
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = UIScreen.main.bounds.width

        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))

        tableView.register(PlacePartnerArticleControllerCell.self, forCellReuseIdentifier: "PlacePartnerArticleControllerCell")
        tableView.register(PlacePartnerArticleControllerCellLoading.self, forCellReuseIdentifier: "PlacePartnerArticleControllerCellLoading")
        return tableView
    }()

    private var headerView: PlaceHeaderView!

    init(controller: PlaceViewController, articles: [Article]) {
        self.place = controller.place!
        self.articles = articles
        self.nextMaxSort = articles.last?.placeSort
        super.init(nibName: nil, bundle: nil)

        self.headerView = PlaceHeaderView(controller: self, place: controller.place, liked: controller.liked)
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

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        self.tableView.delegate = self
        self.tableView.dataSource = self
    }

    private func initViews() {
        self.view.addSubview(tableView)
        self.view.addSubview(headerView)

        tableView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.equalTo(self.view)
        }

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PlacePartnerArticleController: UITableViewDataSource, UITableViewDelegate, SFSafariViewControllerDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return articles.count
        case 1: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = cachedHeight[indexPath.row] {
            return height
        }
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            return tableView.dequeueReusableCell(withIdentifier: "PlacePartnerArticleControllerCellLoading")!
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "PlacePartnerArticleControllerCell") as! PlacePartnerArticleControllerCell
        cell.render(article: articles[indexPath.row], controller: self, indexPath: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            return
        }

        let article = articles[indexPath.row]
        if let articleUrl = article.url, let url = URL(string: articleUrl) {
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            self.present(safari, animated: true, completion: nil)
        }

        Analytics.logEvent("rip_action", parameters: [
            AnalyticsParameterItemCategory: "click_extended_partner_content_article" as NSObject
        ])
    }
}

// Lazy Append Loading
extension PlacePartnerArticleController {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch indexPath {
        case [1, 0]:
            self.appendLoad()
        default: break
        }
    }


    private func appendLoad() {
        if nextMaxSort != nil {
            let cell = self.tableView.cellForRow(at: .init(row: 0, section: 1)) as? PlacePartnerArticleControllerCellLoading
            cell?.indicator.startAnimating()

            MunchApi.places.getArticle(id: self.place.id!, maxSort: nextMaxSort) { meta, articles, nextMaxSort in
                if (meta.isOk()) {
                    self.articles.append(contentsOf: articles)
                    self.nextMaxSort = nextMaxSort

                    if nextMaxSort == nil {
                        cell?.indicator.stopAnimating()
                    }
                    self.tableView.reloadData()
                } else {
                    self.present(meta.createAlert(), animated: true)
                }
            }
        }
    }
}

fileprivate class PlacePartnerArticleControllerCell: UITableViewCell {
    private let bannerImageView: ScaledHeightShimmerImageView = {
        let imageView = ScaledHeightShimmerImageView()
        imageView.tintColor = .white
        return imageView
    }()
    private let authorLabel: UIButton = {
        let label = UIButton()
        label.titleLabel?.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        label.setTitleColor(.white, for: .normal)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.66)
        label.contentEdgeInsets = UIEdgeInsets(topBottom: 3, leftRight: 5)
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 5
        label.isUserInteractionEnabled = false
        return label
    }()
    private let titleLabel: UITextView = {
        let nameLabel = UITextView()
        nameLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .medium)

        nameLabel.textColor = UIColor.black.withAlphaComponent(0.9)
        nameLabel.backgroundColor = .white

        nameLabel.textContainer.maximumNumberOfLines = 2
        nameLabel.textContainer.lineBreakMode = .byTruncatingTail
        nameLabel.textContainer.lineFragmentPadding = 0
        nameLabel.textContainerInset = UIEdgeInsets(topBottom: 0, leftRight: 0)
        nameLabel.isUserInteractionEnabled = false

        nameLabel.translatesAutoresizingMaskIntoConstraints = true
        nameLabel.isScrollEnabled = false
        return nameLabel
    }()
    private let descriptionLabel: UITextView = {
        let nameLabel = UITextView()
        nameLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)

        nameLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        nameLabel.backgroundColor = .white

        nameLabel.textContainer.maximumNumberOfLines = 4
        nameLabel.textContainer.lineBreakMode = .byTruncatingTail
        nameLabel.textContainer.lineFragmentPadding = 0
        nameLabel.textContainerInset = UIEdgeInsets(topBottom: 0, leftRight: 0)
        nameLabel.isUserInteractionEnabled = false

        nameLabel.translatesAutoresizingMaskIntoConstraints = true
        nameLabel.isScrollEnabled = false
        return nameLabel
    }()
    private let readMoreButton: UILabel = {
        let label = UILabel()
        label.text = "Read More"
        label.textColor = UIColor.primary600
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.backgroundColor = .white
        return label
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        let containerView = UIView()
        self.addSubview(containerView)

        containerView.addSubview(bannerImageView)
        containerView.addSubview(authorLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(readMoreButton)

        containerView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(24)
        }

        bannerImageView.snp.makeConstraints { (make) in
            make.left.right.equalTo(containerView)
            make.top.equalTo(containerView).priority(999)

            make.height.greaterThanOrEqualTo(UIScreen.main.bounds.width / 4)
        }

        authorLabel.snp.makeConstraints { make in
            make.left.equalTo(bannerImageView).inset(5)
            make.bottom.equalTo(bannerImageView).inset(5)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(containerView)
            make.top.equalTo(bannerImageView.snp.bottom).inset(-8)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(containerView)
            make.top.equalTo(titleLabel.snp.bottom).inset(-6)
            make.bottom.equalTo(readMoreButton.snp.top).inset(-6)
        }

        readMoreButton.snp.makeConstraints { make in
            make.right.equalTo(containerView)
            make.bottom.equalTo(containerView)
        }
    }

    func render(article: Article, controller: PlacePartnerArticleController, indexPath: IndexPath) {
        bannerImageView.render(images: article.thumbnail) { (image, error, type, url) -> Void in
            if image == nil {
                self.bannerImageView.render(named: "RIP-No-Image")
            }
            // Image Size Caching
//            controller.tableView.reloadRows(at: [indexPath], with: .none)
//            controller.cachedHeight[indexPath.row] = self.bounds.height
        }

        authorLabel.setTitle(article.brand, for: .normal)

        titleLabel.text = article.title

        descriptionLabel.text = article.description
        descriptionLabel.sizeToFit()

        Analytics.logEvent("rip_view", parameters: [
            AnalyticsParameterItemCategory: "extended_partner_content_article" as NSObject
        ])
    }

    fileprivate override func layoutSubviews() {
        super.layoutSubviews()
        self.bannerImageView.layer.cornerRadius = 3
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class PlacePartnerArticleControllerCellLoading: UITableViewCell {
    fileprivate var indicator: NVActivityIndicatorView!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: UIScreen.main.bounds.width, height: 40))
        self.indicator = NVActivityIndicatorView(frame: frame, type: .ballBeat, color: .primary700, padding: 0)
        self.addSubview(indicator)

        indicator.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.height.equalTo(40).priority(999)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}