//
// Created by Fuxing Loh on 2019-03-08.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import Moya
import RxSwift
import Toast_Swift

class RIPCardRating: RIPCard {
    private let ratingLabel = UILabel(style: .h3)
            .with(text: "Rating")
    private let ratingSummary = RatingSummary()
    private let userRating = UserRatingStars()
    private let separatorLine = RIPSeparatorLine()

    private let provider = MunchProvider<UserRatedPlaceService>()
    private let disposeBag = DisposeBag()

    override func didLoad(data: PlaceData!) {
        self.addSubview(ratingSummary) { maker in
            maker.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(12)
        }

        self.addSubview(ratingLabel) { maker in
            maker.left.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(12)
        }

        self.addSubview(userRating) { maker in
            maker.left.equalTo(self).inset(24)
            maker.right.equalTo(ratingSummary.snp.left).inset(-24)
            maker.top.equalTo(ratingLabel.snp.bottom).inset(-6)
        }

        self.addSubview(separatorLine) { maker in
            maker.left.right.equalTo(self)

            maker.top.equalTo(userRating.snp.bottom).inset(-24)
            maker.bottom.equalTo(self).inset(12)
        }

        self.ratingSummary.data = data
        self.userRating.data = data

        userRating.ratingStars.onRate = { (count: Int) in
            self.onRate(count: count, data: data)
        }
    }

    func countToRating(count: Int) -> UserRatedPlace.Rating {
        switch count {
        case 1:
            return .star1
        case 2:
            return .star2
        case 3:
            return .star3
        case 4:
            return .star4
        case 5: fallthrough
        default:
            return .star5
        }

    }

    func onRate(count: Int, data: PlaceData) {
        Authentication.requireAuthentication(controller: self.controller) { state in
            guard case .loggedIn = state else {
                return
            }


            let userRating = UserRatedPlace(userId: nil, placeId: nil, rating: self.countToRating(count: count), status: .published, updatedMillis: nil, createdMillis: nil)
            self.provider.rx.request(.put(data.place.placeId, userRating))
                    .subscribe { event in
                        switch event {
                        case .success:
                            self.userRating.ratingStars.with(count: count)
                            self.controller.view.makeToast("You rated '\(data.place.name)' \(count) Stars.")
                            MunchAnalytic.logEvent("rip_click_rating")
                        case .error(let error):
                            self.controller.alert(error: error)
                        }
                    }
                    .disposed(by: self.disposeBag)
        }
    }
}

class RatingSummary: UIView {
    private let titleLabel = UILabel()
            .with(numberOfLines: 1)
            .with(alignment: .center)
            .with(font: .systemFont(ofSize: 32, weight: .medium))
            .with(color: .ba75)

    private let descriptionLabel = UILabel()
            .with(text: "out of 5")
            .with(alignment: .center)
            .with(numberOfLines: 1)
            .with(font: .systemFont(ofSize: 16, weight: .medium))
            .with(color: .ba75)

    var data: PlaceData? {
        didSet {
            if let average = data?.rating?.summary.average {
                self.isHidden = false
                self.titleLabel.with(text: "\(average.roundTo(places: 1))")
            }
        }
    }

    required override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.isHidden = true

        self.addSubview(titleLabel) { maker in
            maker.left.top.right.equalTo(self)
        }

        self.addSubview(descriptionLabel) { maker in
            maker.top.equalTo(titleLabel.snp.bottom)
            maker.left.right.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class UserRatingStars: UIView {
    private let ratingLabel = UILabel(style: .smallBold)
            .with(numberOfLines: 1)
    let ratingStars = RatingStarArray()

    var data: PlaceData? {
        didSet {
            if let ratedPlace = data?.user?.ratedPlace {
                ratingLabel.with(text: "You Rated:")
                ratingStars.with(count: ratedPlace.rating.count)
            } else {
                ratingLabel.with(text: "Tap to Rate:")
            }
        }
    }

    required override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        self.addSubview(ratingLabel) { maker in
            maker.top.left.right.equalTo(self)
        }

        self.addSubview(ratingStars) { maker in
            maker.left.equalTo(self)
            maker.top.equalTo(ratingLabel.snp.bottom).inset(-2)
            maker.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class RatingStarArray: UIView {
    let star1 = RatingStar()
    let star2 = RatingStar()
    let star3 = RatingStar()
    let star4 = RatingStar()
    let star5 = RatingStar()

    var onRate: ((Int) -> ())?

    required override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        self.star1.addTarget(self, action: #selector(onStar), for: .touchUpInside)
        self.star2.addTarget(self, action: #selector(onStar), for: .touchUpInside)
        self.star3.addTarget(self, action: #selector(onStar), for: .touchUpInside)
        self.star4.addTarget(self, action: #selector(onStar), for: .touchUpInside)
        self.star5.addTarget(self, action: #selector(onStar), for: .touchUpInside)

        self.addSubview(star1) { (maker: ConstraintMaker) -> Void in
            maker.top.bottom.equalTo(self)
            maker.left.equalTo(self).inset(-6)
        }

        self.addSubview(star2) { (maker: ConstraintMaker) -> Void in
            maker.top.bottom.equalTo(self)
            maker.left.equalTo(star1.snp.right)
        }

        self.addSubview(star3) { (maker: ConstraintMaker) -> Void in
            maker.top.bottom.equalTo(self)
            maker.left.equalTo(star2.snp.right)
        }

        self.addSubview(star4) { (maker: ConstraintMaker) -> Void in
            maker.top.bottom.equalTo(self)
            maker.left.equalTo(star3.snp.right)
        }

        self.addSubview(star5) { (maker: ConstraintMaker) -> Void in
            maker.top.bottom.equalTo(self)
            maker.left.equalTo(star4.snp.right)
            maker.right.equalTo(self).inset(-6)
        }
    }

    @objc func onStar(_ star: RatingStar) {
        if let onRate = onRate {
            if star == star1 {
                onRate(1)
            } else if star == star2 {
                onRate(2)
            } else if star == star3 {
                onRate(3)
            } else if star == star4 {
                onRate(4)
            } else if star == star5 {
                onRate(5)
            }
        }
    }

    func with(count: Int) {
        star1.filled = count >= 1
        star2.filled = count >= 2
        star3.filled = count >= 3
        star4.filled = count >= 4
        star5.filled = count >= 5
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class RatingStar: UIControl {
    private let imageView = UIImageView()
    var filled: Bool = false {
        didSet {
            if filled {
                self.imageView.image = UIImage(named: "RIP_Rating_Filled")
            } else {
                self.imageView.image = UIImage(named: "RIP_Rating")
            }
        }
    }

    required override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        self.imageView.tintColor = .secondary500
        self.addSubview(imageView) { maker in
            maker.edges.equalTo(self).inset(6)
            maker.size.equalTo(24)
        }

        self.imageView.image = UIImage(named: "RIP_Rating")
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}