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

class PlacePartnerContentController: UIViewController, UIGestureRecognizerDelegate {
    let placeId: String
    let place: Place

    fileprivate var startFromUniqueId: String?
    fileprivate var more = true
    fileprivate var contents: [PartnerContent] = []
    fileprivate var mediaMaxSort: String? = nil
    fileprivate var articleMaxSort: String? = nil

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 40

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.alwaysBounceHorizontal = false
        collectionView.backgroundColor = UIColor.white
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 36, right: 0)

        collectionView.register(PlacePartnerContentControllerCell.self, forCellWithReuseIdentifier: "PlacePartnerContentControllerCell")
        collectionView.register(PlacePartnerContentControllerCellEmpty.self, forCellWithReuseIdentifier: "PlacePartnerContentControllerCellEmpty")
        collectionView.register(PlacePartnerContentControllerCellLoading.self, forCellWithReuseIdentifier: "PlacePartnerContentControllerCellLoading")
        return collectionView
    }()

    private let headerView = PlacePartnerContentHeaderView()

    init(place: Place, startFromUniqueId: String? = nil) {
        self.placeId = place.id!
        self.place = place
        self.startFromUniqueId = startFromUniqueId
        super.init(nibName: nil, bundle: nil)
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

        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        self.headerView.backButton.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)
    }

    private func initViews() {
        self.view.addSubview(collectionView)
        self.view.addSubview(headerView)

        collectionView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.equalTo(self.view)
        }

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
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

fileprivate class PlacePartnerContentHeaderView: UIView {
    fileprivate let backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "NavigationBar-Back"), for: .normal)
        button.tintColor = .black
        button.imageEdgeInsets.left = 18
        button.contentHorizontalAlignment = .left
        return button
    }()

    fileprivate let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Partners Content"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.black.withAlphaComponent(0.75)
        return label
    }()

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.initViews()
    }

    private func initViews() {
        self.backgroundColor = .white
        self.addSubview(backButton)
        self.addSubview(titleLabel)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.bottom.equalTo(self)
            make.left.equalTo(self)

            make.width.equalTo(64)
            make.height.equalTo(44)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.height.equalTo(44)
            make.centerX.equalTo(self)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: 2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PlacePartnerContentController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SFSafariViewControllerDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return contents.count
        case 1: return 1
        default: return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 1 {
            return CGSize(width: UIScreen.main.bounds.width, height: 40)
        }

        return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 0.85)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 1 {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "PlacePartnerContentControllerCellLoading", for: indexPath)
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlacePartnerContentControllerCell", for: indexPath) as! PlacePartnerContentControllerCell
        cell.render(content: contents[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            return
        }

        let content = contents[indexPath.row]
        switch content.type {
        case "article":
            if let articleUrl = content.article?.url, let url = URL(string: articleUrl) {
                let safari = SFSafariViewController(url: url)
                safari.delegate = self
                self.present(safari, animated: true, completion: nil)
            }

            Analytics.logEvent("rip_extended_action", parameters: [
                AnalyticsParameterItemCategory: "click_partner_content_article" as NSObject
            ])
        case "instagram-media":
            if let username = content.instagramMedia?.username, let url = URL(string: "https://instagram.com/" + username) {
                let safari = SFSafariViewController(url: url)
                safari.delegate = self
                self.present(safari, animated: true, completion: nil)
            }

            Analytics.logEvent("rip_extended_action", parameters: [
                AnalyticsParameterItemCategory: "click_partner_content_instagram" as NSObject
            ])
        default: return
        }
    }
}

// Lazy Append Loading
extension PlacePartnerContentController {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        switch indexPath {
        case [1, 0]:
            self.appendLoad()
        default: break
        }
    }

    private func appendLoad() {
        if more {
            more = false

            MunchApi.places.getPartnerContent(id: self.placeId, mediaMaxSort: mediaMaxSort, articleMaxSort: articleMaxSort) { meta, contents, mediaMaxSort, articleMaxSort in
                if (meta.isOk()) {
                    self.contents.append(contentsOf: contents)
                    self.mediaMaxSort = mediaMaxSort
                    self.articleMaxSort = articleMaxSort
                    self.more = mediaMaxSort != nil || articleMaxSort != nil

                    if !self.more {
                        let cell = self.collectionView.cellForItem(at: .init(row: 0, section: 1)) as? PlacePartnerContentControllerCellLoading
                        cell?.stopAnimating()
                    }
                    self.collectionView.reloadData()

                    if let startFromUniqueId = self.startFromUniqueId {
                        if let index = self.contents.index(where: { $0.uniqueId == startFromUniqueId }) {
                            self.collectionView.scrollToItem(at: .init(row: index, section: 0), at: .top, animated: false)
                            self.startFromUniqueId = nil
                        }
                    }
                } else {
                    self.present(meta.createAlert(), animated: true)
                }
            }
        }
    }
}

fileprivate class PlacePartnerContentControllerCell: UICollectionViewCell {
    private let bannerImageView: ShimmerImageView = {
        let imageView = ShimmerImageView()
        imageView.tintColor = .white
        return imageView
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 18.0, weight: .medium)
        label.textColor = UIColor.black.withAlphaComponent(0.9)
        return label
    }()
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        label.textColor = UIColor.black.withAlphaComponent(0.55)
        return label
    }()
    private let descriptionLabel: UITextView = {
        let nameLabel = UITextView()
        nameLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)

        nameLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        nameLabel.backgroundColor = .white

        nameLabel.textContainer.maximumNumberOfLines = 3
        nameLabel.textContainer.lineBreakMode = .byTruncatingTail
        nameLabel.textContainer.lineFragmentPadding = 0
        nameLabel.textContainerInset = UIEdgeInsets(topBottom: 0, leftRight: 0)
        nameLabel.isUserInteractionEnabled = false
        return nameLabel
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        let containerView = UIView()
        self.addSubview(containerView)
        containerView.addSubview(bannerImageView)
        containerView.addSubview(authorLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)

        containerView.snp.makeConstraints { make in
            make.left.equalTo(self)
            make.right.equalTo(self)
            make.top.bottom.equalTo(self)
        }

        bannerImageView.snp.makeConstraints { (make) in
            make.left.right.equalTo(containerView)
            make.top.equalTo(containerView)
            make.height.equalTo(containerView.snp.height).dividedBy(1.5).priority(999)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(containerView).inset(16)
            make.top.equalTo(bannerImageView.snp.bottom).inset(-8)
        }

        authorLabel.snp.makeConstraints { make in
            make.left.equalTo(containerView).inset(16)
            make.top.equalTo(titleLabel.snp.bottom).inset(-2)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(containerView).inset(16)
            make.top.equalTo(authorLabel.snp.bottom).inset(-6)
            make.bottom.equalTo(containerView)
        }
    }

    func render(content: PartnerContent) {
        bannerImageView.render(images: content.image) { (image, error, type, url) -> Void in
            if image == nil {
                self.bannerImageView.render(named: "RIP-No-Image")
            }
        }

        titleLabel.text = content.title
        authorLabel.text = content.author
        descriptionLabel.text = content.description

        Analytics.logEvent("rip_extended_view", parameters: [
            AnalyticsParameterItemCategory: "partner_content" as NSObject
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class PlacePartnerContentControllerCellLoading: UICollectionViewCell {
    private var indicator: NVActivityIndicatorView!

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: UIScreen.main.bounds.width, height: 40))
        self.indicator = NVActivityIndicatorView(frame: frame, type: .ballBeat, color: .primary700, padding: 0)
        indicator.startAnimating()
        self.addSubview(indicator)

        indicator.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.height.equalTo(40)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimating() {
        self.indicator.startAnimating()
    }

    func stopAnimating() {
        self.indicator.stopAnimating()
    }
}

fileprivate class PlacePartnerContentControllerCellEmpty: UICollectionViewCell {
    private let label: UILabel = {
        let label = UILabel()
        label.text = "No Result Found"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.regular)
        return label
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(label)

        label.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.bottom.equalTo(self)
            make.height.equalTo(40).priority(999)
        }
    }

    func render(text: String) {
        label.text = text
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}