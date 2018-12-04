//
// Created by Fuxing Loh on 2018-12-04.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class FeedImageController: UIViewController, UIGestureRecognizerDelegate {
    private let provider = MunchProvider<FeedImageService>()

    private let headerView = FeedImageHeaderView()
    private let scrollView = UIScrollView()
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        return stackView
    }()

    private let item: ImageFeedItem
    private let places: [Place]

    required init(item: ImageFeedItem, places: [Place]) {
        self.item = item
        self.places = places
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
        self.view.backgroundColor = .white
        self.view.addSubview(scrollView)
        self.view.addSubview(headerView)

        self.scrollView.addSubview(self.stackView)
        self.addArrangedSubview()

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.headerView.backButton.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)

        headerView.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(self.view)
        }

        scrollView.snp.makeConstraints { maker in
            maker.top.equalTo(headerView.snp.bottom)
            maker.left.right.bottom.equalTo(self.view)
        }

        stackView.snp.makeConstraints { maker in
            maker.edges.equalTo(scrollView)
            maker.width.equalTo(scrollView.snp.width)
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

class FeedImageHeaderView: UIView {
    let backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "NavigationBar-Back"), for: .normal)
        button.tintColor = .black
        button.imageEdgeInsets.left = 18
        button.contentHorizontalAlignment = .left
        return button
    }()

    required init() {
        super.init(frame: .zero)
        self.backgroundColor = .white
        self.addSubview(backButton)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.left.bottom.equalTo(self)

            make.width.equalTo(56)
            make.height.equalTo(44)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: 1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FeedImageController {
    func addArrangedSubview() {
        self.stackView.addArrangedSubview(FeedImage(item: self.item))
        self.stackView.addArrangedSubview(FeedButtonGroup(item: self.item))
        self.stackView.addArrangedSubview(FeedContent(item: self.item))
        if let place = self.places.get(0) {
            self.stackView.addArrangedSubview(FeedPlace(place: place))
        }
    }
}

fileprivate class FeedImage: UIView {
    let imageView: SizeImageView = {
        let imageView = SizeImageView(points: UIScreen.main.bounds.width, height: 1)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        return imageView
    }()

    init(item: ImageFeedItem) {
        super.init(frame: .zero)
        self.addSubview(imageView)

        imageView.render(image: item.image)
        imageView.snp.makeConstraints { maker in
            maker.edges.equalTo(self).priority(999)
            if let size = item.image.maxSize {
                maker.height.equalTo(imageView.snp.width).multipliedBy(size.heightMultiplier)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class FeedButtonGroup: UIView {
    let saveButton = MunchButton(style: .borderSmall).with(text: "Save")
    let placeButton = MunchButton(style: .primarySmall).with(text: "Open Place")

    init(item: ImageFeedItem) {
        super.init(frame: .zero)
        self.addSubview(saveButton)
        self.addSubview(placeButton)

        saveButton.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self).inset(24)
            maker.right.equalTo(placeButton.snp.left).inset(-16)
        }

        placeButton.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(saveButton)
            maker.right.equalTo(self).inset(24)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class FeedContent: UIView {
    let caption = UILabel(style: .subtext)
            .with(numberOfLines: 2)
    let username = UILabel(style: .h5)
            .with(numberOfLines: 1)

    init(item: ImageFeedItem) {
        super.init(frame: .zero)
        self.addSubview(caption)
        self.addSubview(username)

        caption.text = item.instagram?.caption
        username.text = "by \(item.instagram?.username ?? "") on \(item.createdMillis.asMonthDayYear)"

        caption.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(self)
        }

        username.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(caption.snp.bottom).inset(-8)
            maker.bottom.equalTo(self).inset(16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class FeedPlace: UIView {
    let label = UILabel(style: .h2)
            .with(text: "Place Mentioned")
    let placeCard = PlaceCard()

    init(place: Place) {
        super.init(frame: .zero)
        self.addSubview(label)
        self.addSubview(placeCard)

        label.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(16)
            maker.height.equalTo(32)
        }

        placeCard.place = place
        placeCard.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.bottom.equalTo(self).inset(80)
            maker.top.equalTo(label.snp.bottom).inset(-24)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}