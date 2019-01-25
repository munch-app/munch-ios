//
// Created by Fuxing Loh on 2018-12-20.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import SafariServices

import PullToDismiss
import SwiftRichString

class RIPImageController: UIPageViewController {

    private let index: Int
    private let loader: RIPImageLoader
    private let headerView = RIPImageHeaderView()

    init(index: Int, loader: RIPImageLoader, place: Place) {
        self.index = index
        self.loader = loader
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)

        headerView.titleView.text = "\(place.name)"
        self.view.addSubview(headerView)
        headerView.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(self.view)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataSource = self
        self.delegate = self

        MunchAnalytic.logEvent("rip_view_image", parameters: ["index": index as NSObject])
        let controller = RIPImageDetailController(index: index, item: loader.items[index], controller: self)
        self.setViewControllers([controller], direction: .forward, animated: true, completion: nil)

        self.headerView.closeButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MunchAnalytic.setScreen("/places/images")
    }

    @objc func actionCancel(_ sender: Any) {
        self.dismiss(animated: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class RIPImageHeaderView: UIView {
    let titleView = UILabel(style: .navHeader)
            .with(text: "Images")
    let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Search-Header-Close"), for: .normal)
        button.tintColor = .black
        button.imageEdgeInsets.right = 24
        button.contentHorizontalAlignment = .right
        return button
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.backgroundColor = .white

        self.addSubview(titleView)
        self.addSubview(closeButton)

        titleView.snp.makeConstraints { maker in
            maker.top.equalTo(self.safeArea.top)
            maker.bottom.equalTo(self)

            maker.left.equalTo(self).inset(24)
            maker.right.equalTo(closeButton.snp.left).inset(-16)
        }

        closeButton.snp.makeConstraints { maker in
            maker.top.equalTo(self.safeArea.top)
            maker.bottom.equalTo(self)

            maker.right.equalTo(self)
            maker.height.equalTo(44)
            maker.width.equalTo(24 + 24)
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

extension RIPImageController: UIPageViewControllerDataSource {
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let prevController = viewController as? RIPImageDetailController else {
            return nil
        }

        let index = prevController.index - 1
        if index < 0 {
            return nil
        }

        MunchAnalytic.logEvent("rip_view_image", parameters: ["index": index as NSObject])
        return RIPImageDetailController(index: index, item: loader.items[index], controller: self)
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let prevController = viewController as? RIPImageDetailController else {
            return nil
        }

        let index = prevController.index + 1
        if index >= loader.items.count {
            return nil
        }
        if index > loader.items.count - 5 {
            self.loader.append()
        }

        MunchAnalytic.logEvent("rip_view_image", parameters: ["index": index as NSObject])
        return RIPImageDetailController(index: index, item: loader.items[index], controller: self)
    }
}

extension RIPImageController: UIPageViewControllerDelegate {

}

class RIPImageDetailController: UIViewController, SFSafariViewControllerDelegate {
    fileprivate var index: Int
    fileprivate var item: RIPImageItem

    private let controller: RIPImageController
    private let pullToDismiss: PullToDismiss
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    private let titleLabel = UILabel(style: .h4).with(numberOfLines: 1)
    private let authorLabel = UILabel(style: .h6).with(numberOfLines: 1)

    private let topControl = UIControl()

    private let descriptionLabel = UILabel(style: .regular)
            .with(numberOfLines: 3)
    private let readButton = MunchButton(style: .secondaryOutline)
            .with(text: "Read More")

    private let imageView: SizeImageView = {
        let imageView = SizeShimmerImageView(points: UIScreen.main.bounds.width, height: 1)
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .ba75
        return imageView
    }()

    init(index: Int, item: RIPImageItem, controller: RIPImageController) {
        self.controller = controller
        self.pullToDismiss = PullToDismiss(scrollView: scrollView, viewController: controller)
        self.pullToDismiss.dismissableHeightPercentage = 0.4
        self.index = index
        self.item = item
        super.init(nibName: nil, bundle: nil)

        topControl.addSubview(titleLabel)
        topControl.addSubview(authorLabel)
        scrollView.addSubview(topControl)

        scrollView.addSubview(imageView)
        scrollView.addSubview(descriptionLabel)
        scrollView.addSubview(readButton)

        self.view.backgroundColor = .white
        self.view.addSubview(scrollView)

        scrollView.snp.makeConstraints { maker in
            maker.top.equalTo(self.view.safeArea.top).inset(44)
            maker.bottom.left.right.equalTo(self.view)
        }

        topControl.addTarget(self, action: #selector(onReadMore), for: .touchUpInside)
        topControl.snp.makeConstraints { maker in
            maker.top.equalTo(self.scrollView).inset(24)
            maker.left.right.equalTo(self.view)

            titleLabel.snp.makeConstraints { maker in
                maker.top.equalTo(topControl)
                maker.left.right.equalTo(topControl).inset(24)
            }

            authorLabel.snp.makeConstraints { maker in
                maker.top.equalTo(titleLabel.snp.bottom).inset(-8)
                maker.left.right.equalTo(topControl).inset(24)
                maker.bottom.equalTo(topControl)
            }
        }

        imageView.snp.makeConstraints { maker in
            maker.top.equalTo(topControl.snp.bottom).inset(-16)
            maker.left.right.equalTo(self.view)

            switch item {
            case .image(let image):
                if let max = image.sizes.max {
                    maker.height.equalTo(imageView.snp.width).multipliedBy(max.heightMultiplier)
                }
            }
        }

        descriptionLabel.snp.makeConstraints { maker in
            maker.top.equalTo(imageView.snp.bottom).inset(-24)
            maker.left.right.equalTo(self.view).inset(24)
        }

        readButton.addTarget(self, action: #selector(onReadMore), for: .touchUpInside)
        readButton.snp.makeConstraints { maker in
            maker.top.equalTo(descriptionLabel.snp.bottom).inset(-24)
            maker.right.equalTo(self.view).inset(24)
            maker.bottom.equalTo(self.scrollView).inset(24)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        switch item {
        case .image(let image):

            func setAuthor(name: String) {
                let mutable = NSMutableAttributedString()
                mutable.append(NSAttributedString(string: "by "))
                mutable.append(name.set(style: Style({ $0.color = UIColor.secondary700 })))
                mutable.append(NSAttributedString(string: " on \(image.createdMillis?.asMonthDayYear ?? "")"))
                self.authorLabel.attributedText = mutable
            }

            if let article = image.article {
                titleLabel.text = image.title
                descriptionLabel.text = image.caption

                setAuthor(name: article.domain.name)
            } else if let instagram = image.instagram {
                titleLabel.text = image.caption
                descriptionLabel.text = image.caption

                setAuthor(name: instagram.username ?? "")
                readButton.isHidden = true
            }

            imageView.render(sizes: image.sizes)
        }
    }

    @objc func onReadMore() {
        func alert(message: String, url: String?, event: String) {
            guard let url = url else {
                return
            }
            guard let link = URL(string: url) else {
                return
            }

            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Open", style: .default) { action in
                let safari = SFSafariViewController(url: link)
                safari.delegate = self

                MunchAnalytic.logEvent(event)
                self.controller.present(safari, animated: true, completion: nil)
            })
            self.controller.present(alert, animated: true)
        }
        
        switch item {
        case .image(let image):
            if let article = image.article {
                alert(message: "Open Article?", url: article.url, event: "rip_click_article")
            } else if let instagram = image.instagram {
                alert(message: "Open Instagram?", url: instagram.link, event: "rip_click_image")
            }
        }
    }

    @objc func onContent(_ sender: Any) {

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}