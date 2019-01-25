//
// Created by Fuxing Loh on 2018-12-04.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import SwiftRichString
import SafariServices

class FeedImageController: UIViewController, UIGestureRecognizerDelegate {
    private let provider = MunchProvider<FeedImageService>()

    private let headerView = FeedImageHeaderView()

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.contentInsetAdjustmentBehavior = .never
        return view
    }()
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        return stackView
    }()

    private let item: ImageFeedItem
    private let places: [Place]

    private var place: Place? {
        return places.get(0)
    }

    required init(item: ImageFeedItem, places: [Place]) {
        self.item = item
        self.places = places
        super.init(nibName: nil, bundle: nil)
        self.hidesBottomBarWhenPushed = true
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
        self.view.backgroundColor = .white
        self.view.addSubview(scrollView)
        self.view.addSubview(headerView)

        self.scrollView.addSubview(self.stackView)

        self.addArrangedSubview()
        self.addTargets()

        headerView.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(self.view)
        }

        scrollView.snp.makeConstraints { maker in
            maker.top.equalTo(self.view)
            maker.left.right.equalTo(self.view)
            maker.bottom.equalTo(self.view)
        }

        stackView.snp.makeConstraints { maker in
            maker.edges.equalTo(scrollView)
            maker.width.equalTo(scrollView.snp.width)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MunchAnalytic.setScreen("/feed/images")
        MunchAnalytic.logEvent("feed_view")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FeedImageController {
    func addArrangedSubview() {
        self.stackView.addArrangedSubview(FeedImageViewImage(item: self.item))
        self.stackView.addArrangedSubview(FeedImageViewContent(item: self.item))
        if let place = self.place {
            self.stackView.addArrangedSubview(FeedImageViewPlace(place: place, controller: self))
        }
    }
}

// MARK: Add Targets
extension FeedImageController: SFSafariViewControllerDelegate {
    func addTargets() {
        self.scrollView.delegate = self

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        self.headerView.backButton.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)

        if let place = place {
            self.headerView.titleView.text = place.name
        }

        if let contentView = self.stackView.arrangedSubviews[1] as? FeedImageViewContent {
            contentView.addTarget(self, action: #selector(onContent(_:)), for: .touchUpInside)
        }

        if let placeView = self.stackView.arrangedSubviews[2] as? FeedImageViewPlace {
            placeView.addTarget(self, action: #selector(onPlace(_:)), for: .touchUpInside)
        }
    }

    @objc func onContent(_ sender: Any) {
        if let link = self.item.instagram?.link, let url = URL(string: link) {
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            present(safari, animated: true, completion: nil)
        }
    }

    @objc func onPlace(_ sender: Any) {
        if let place = self.places.get(0) {
            let controller = RIPController(placeId: place.placeId)
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    @objc func onBackButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: Scrolling
extension FeedImageController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateNavigationBackground(y: scrollView.contentOffset.y)
    }

    func updateNavigationBackground(y: CGFloat) {
        if (120 < y) {
            headerView.isOpaque = true
        } else {
            headerView.isOpaque = false
        }
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        let y = self.scrollView.contentOffset.y
        if (120 < y) {
            return .default
        } else {
            return .lightContent
        }
    }
}