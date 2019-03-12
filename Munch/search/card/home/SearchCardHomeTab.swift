//
// Created by Fuxing Loh on 2018-11-30.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import RxSwift

class SearchHomeTabCard: SearchCardView {
    let titleLabel = UILabel(style: .h2)
            .with(numberOfLines: 0)

    static let createText = "(Not Samantha? Create an account here.)"
    let createBtn: UIControl = {
        let label = UILabel(style: .h6)
                .with(text: createText)

        let button = UIControl()
        button.addSubview(label)

        label.snp.makeConstraints { maker in
            maker.edges.equalTo(button)
        }
        return button
    }()

    let collectionView: UICollectionView = {
        let layout = MunchHorizontalSnap()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        layout.itemSize = SearchHomeFeatureSlide.size()

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = .white
        return collectionView
    }()

    var slides = [
        FeatureSlide.Between,
        FeatureSlide.Nearby,
    ]

    private let disposeBag = DisposeBag()

    override func didLoad(card: SearchCard) {
        self.addSubview(titleLabel)
        self.addSubview(createBtn)
        self.addSubview(collectionView)

        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(self).inset(topBottom)
        }

        createBtn.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(titleLabel.snp.bottom).inset(-4)
        }
        self.layoutIfNeeded()

        collectionView.snp.makeConstraints { maker in
            if Authentication.isAuthenticated() {
                createBtn.isHidden = true
                maker.top.equalTo(titleLabel.snp.bottom).inset(-24)
            } else {
                createBtn.isHidden = false
                maker.top.equalTo(createBtn.snp.bottom).inset(-24)
            }


            maker.left.right.equalTo(self)
            maker.bottom.equalTo(self).inset(topBottom).priority(.high)
            maker.height.equalTo(SearchHomeFeatureSlide.size().height).priority(.medium)
        }

        self.createBtn.addTarget(self, action: #selector(onCreateAccount), for: .touchUpInside)
        self.registerCells(collectionView: self.collectionView)
    }

    override func willDisplay(card: SearchCard) {
        createBtn.isHidden = Authentication.isAuthenticated()
        self.titleLabel.text = SearchHomeTabCard.title
    }

    override class func height(card: SearchCard) -> CGFloat {
        let title = FontStyle.h2.height(text: SearchHomeTabCard.title, width: self.contentWidth)
        let min = topBottom + title + 24 + SearchHomeFeatureSlide.size().height + topBottom

        if Authentication.isAuthenticated() {
            return min
        }
        return min + 4 + FontStyle.h6.height(text: createText, width: self.contentWidth)
    }

    override class var cardId: String {
        return "HomeTab_2018-11-29"
    }
}

extension SearchHomeTabCard: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func registerCells(collectionView: UICollectionView) {
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.register(type: SearchHomeFeatureSlide.self)
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return slides.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeue(type: SearchHomeFeatureSlide.self, for: indexPath)
                .render(with: slides[indexPath.row])
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch slides[indexPath.row] {
        case .Between:
            let controller = FilterLocationBetweenController(searchQuery: self.controller.searchQuery) { query in
                if let query = query {
                    self.controller.push(searchQuery: query)
                }
            }
            self.controller.present(controller, animated: true)

        case .Nearby:
            MunchLocation.request(force: true, permission: true).subscribe { event in
                guard case let .success(ll) = event, let _ = ll else {
                    return
                }

                var query = SearchQuery(feature: .Search)
                query.filter.location.type = .Nearby
                self.controller.push(searchQuery: query)
            }.disposed(by: disposeBag)
        }
    }
}

extension SearchHomeTabCard {
    @objc func onCreateAccount() {
        Authentication.requireAuthentication(controller: self.controller) { state in
            guard case .loggedIn = state else {
                return
            }

            self.controller.reset()
        }
    }
}

extension SearchHomeTabCard {
    class var title: String {
        return "\(salutation), \(name). Meeting someone for a meal?"
    }

    class var salutation: String {
        let date = Date()
        let hour = Calendar.current.component(.hour, from: date)
        let minute = Calendar.current.component(.minute, from: date)

        let total = (hour * 60) + minute
        if total >= 300 && total < 720 {
            return "Good Morning"
        } else if total >= 720 && total < 1020 {
            return "Good Afternoon"
        } else {
            return "Good Evening"
        }
    }

    class var name: String {
        if !Authentication.isAuthenticated() {
            return "Samantha"
        }
        return UserProfile.instance?.name ?? "Samantha"
    }
}

enum FeatureSlide {
    case Between
    case Nearby

    var title: String {
        switch self {
        case .Between:
            return "Find the ideal spot for everyone with EatBetween."
        case .Nearby:
            return "Explore places around you."
        }
    }

    var backgroundImage: UIImage? {
        switch self {
        case .Between:
            return UIImage(named: "Home_Feature_EatBetween")
        case .Nearby:
            return UIImage(named: "Home_Feature_Nearby")
        }
    }

    var buttonStyle: MunchButtonStyle {
        switch self {
        case .Between:
            return .secondary
        case .Nearby:
            return .primary
        }
    }

    var buttonText: String {
        switch self {
        case .Between:
            return "Try EatBetween"
        case .Nearby:
            return "Discover Nearby"
        }
    }
}

class SearchHomeFeatureSlide: UICollectionViewCell {
    private static let width = (UIScreen.main.bounds.size.width - 48)
    private static let height = width * 0.6

    private let image: SizeImageView = {
        let imageView = SizeShimmerImageView(points: width, height: height)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 3
        return imageView
    }()

    private let titleLabel = UILabel(style: .h4)
            .with(font: .systemFont(ofSize: 18, weight: .semibold))
            .with(numberOfLines: 0)
            .with(color: .white)
            .with(alignment: .left)

    private let button = MunchButton(style: .secondary)
            .with { button in
                button.isUserInteractionEnabled = false
            }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(image) { (maker: ConstraintMaker) -> Void in
            maker.edges.equalTo(self)
        }

        self.addSubview(titleLabel) { (maker: ConstraintMaker) -> Void in
            maker.left.equalTo(image).inset(20)
            maker.right.equalTo(self.snp.centerX)
            maker.top.equalTo(image).inset(16)
        }

        self.addSubview(button) { maker in
            maker.left.equalTo(self).inset(20)
            maker.bottom.equalTo(self).inset(16)
        }
    }

    func render(with feature: FeatureSlide) -> SearchHomeFeatureSlide {
        image.image = feature.backgroundImage
        titleLabel.text = feature.title
        button.with(style: feature.buttonStyle)
                .with(text: feature.buttonText)
        return self
    }

    static func size() -> CGSize {
        return CGSize(width: width, height: height)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
