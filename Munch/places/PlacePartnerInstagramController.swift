//
// Created by Fuxing Loh on 8/1/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

import Moya
import RxSwift

import SnapKit
import SwiftyJSON
import SwiftRichString
import NVActivityIndicatorView

class PlacePartnerInstagramController: UIViewController, UIGestureRecognizerDelegate {
    let place: Place
    let controller: PlaceController

    let provider = MunchProvider<PlacePartnerService>()
    let disposeBag = DisposeBag()

    fileprivate var cachedHeight = [Int: CGFloat]()

    fileprivate var medias: [InstagramMedia] = []
    fileprivate var nextPlaceSort: String? = nil

    fileprivate let tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.allowsSelection = true
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = UIScreen.main.bounds.width

        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))

        tableView.register(PlacePartnerInstagramControllerCell.self, forCellReuseIdentifier: "PlacePartnerInstagramControllerCell")
        tableView.register(PlacePartnerInstagramControllerCellLoading.self, forCellReuseIdentifier: "PlacePartnerInstagramControllerCellLoading")
        return tableView
    }()

    private var headerView: PlaceHeaderView!

    init(controller: PlaceController, medias: [InstagramMedia], nextPlaceSort: String?) {
        self.place = controller.place!
        self.controller = controller

        self.medias = medias
        self.nextPlaceSort = nextPlaceSort
        super.init(nibName: nil, bundle: nil)

        self.headerView = PlaceHeaderView(controller: self, place: controller.place)

        if medias.isEmpty && nextPlaceSort == nil {
            self.appendLoad(force: true)
        }
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

extension PlacePartnerInstagramController: UITableViewDataSource, UITableViewDelegate, SFSafariViewControllerDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return medias.count
        case 1: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (indexPath.section, indexPath.row) {
        case (0, let row):
            if let image = medias[row].image, let size = image.sizes.first {
                let modifier: CGFloat = PlacePartnerInstagramControllerCell.width / CGFloat(size.width)
                return CGFloat(size.height) * modifier
            }
        default: break
        }
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            return tableView.dequeueReusableCell(withIdentifier: "PlacePartnerInstagramControllerCellLoading")!
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "PlacePartnerInstagramControllerCell") as! PlacePartnerInstagramControllerCell
        cell.render(media: medias[indexPath.row], controller: self, indexPath: indexPath)
        if indexPath.row > 3 {
            self.controller.apply(navigation: .partnerInstagramItem(indexPath.row))
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            return
        }

        let media = medias[indexPath.row]
        if let link = media.link, let url = URL(string: link) {
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            self.present(safari, animated: true, completion: nil)
        }

        self.controller.apply(click: .partnerInstagramItem(indexPath.row))
    }
}

// Lazy Append Loading
extension PlacePartnerInstagramController {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch indexPath {
        case [1, 0]:
            self.appendLoad()
        default: break
        }
    }

    private func appendLoad(force: Bool = false) {
        if nextPlaceSort != nil || force {
            let cell = self.tableView.cellForRow(at: .init(row: 0, section: 1)) as? PlacePartnerInstagramControllerCellLoading
            cell?.indicator.startAnimating()

            provider.rx.request(.medias(self.place.placeId, self.nextPlaceSort, 20))
                    .map { response throws -> ([InstagramMedia], String?) in
                        let sort = try response.mapNext(atKeyPath: "sort") as? String
                        return try (response.map(data: [InstagramMedia].self), sort)
                    }.subscribe { event in
                        switch event {
                        case .success(let medias, let nextPlaceSort):
                            self.medias.append(contentsOf: medias)
                            self.nextPlaceSort = nextPlaceSort

                            if nextPlaceSort == nil {
                                cell?.indicator.stopAnimating()
                            }
                            self.tableView.reloadData()
                        case .error(let error):
                            self.alert(error: error)
                        }
                    }.disposed(by: disposeBag)
        }
    }
}

fileprivate class PlacePartnerInstagramControllerCell: UITableViewCell {
    static let width = UIScreen.main.bounds.width - 48
    let bannerImageView: SizeImageView = {
        let imageView = SizeImageView(points: width, height: width)
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
    private let descriptionLabel: UITextView = {
        let nameLabel = UITextView()
        nameLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)

        nameLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        nameLabel.backgroundColor = .white

        nameLabel.textContainer.maximumNumberOfLines = 3
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
        label.text = "More from"
        label.textColor = UIColor.black.withAlphaComponent(0.75)
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
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(readMoreButton)

        containerView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(24)
        }

        authorLabel.snp.makeConstraints { make in
            make.left.equalTo(bannerImageView).inset(5)
            make.bottom.equalTo(bannerImageView).inset(5)
        }

        bannerImageView.snp.makeConstraints { (make) in
            make.left.right.equalTo(containerView)
            make.top.equalTo(containerView)
            make.height.equalTo(UIScreen.main.bounds.width - 48)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(containerView)
            make.top.equalTo(bannerImageView.snp.bottom).inset(-6)
            make.bottom.equalTo(readMoreButton.snp.top).inset(-6)
        }

        readMoreButton.snp.makeConstraints { make in
            make.right.equalTo(containerView)
            make.bottom.equalTo(containerView)
        }
    }

    func render(media: InstagramMedia, controller: PlacePartnerInstagramController, indexPath: IndexPath) {
        // Dynamic Image Sizing
        if let image = media.image {
            bannerImageView.render(image: image)
        } else {
            bannerImageView.render(named: "RIP-No-Image")
        }

        authorLabel.setTitle("@\(media.user?.username ?? "")", for: .normal)

        descriptionLabel.text = media.caption
        descriptionLabel.sizeToFit()

        readMoreButton.text = "More from @\(media.user?.username ?? "")"
    }

    fileprivate override func layoutSubviews() {
        super.layoutSubviews()
        self.bannerImageView.layer.cornerRadius = 3
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class PlacePartnerInstagramControllerCellLoading: UITableViewCell {
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