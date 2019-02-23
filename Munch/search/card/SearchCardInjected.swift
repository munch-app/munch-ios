//
//  SearchCardInjected.swift
//  Munch
//
//  Created by Fuxing Loh on 20/10/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import RxSwift

import Localize_Swift

class SearchNoLocationCard: SearchCardView {
    private let titleImage = UIImageView()
    private let titleLabel = UILabel(style: .h2)
            .with(text: "No Location")

    private let descriptionLabel = UILabel(style: .regular)
            .with(text: "You have turned off your location service. Turn it on for better suggestion?")
            .with(numberOfLines: 0)
    private let actionButton = MunchButton(style: .secondary)
            .with(text: "Enable Location")

    private var disposeBag = DisposeBag()

    override func didLoad(card: SearchCard) {
        self.addSubview(titleImage)
        self.addSubview(titleLabel)
        self.addSubview(descriptionLabel)
        self.addSubview(actionButton)

        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(topBottom)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(titleLabel.snp.bottom).inset(-20)
        }

        actionButton.addTarget(self, action: #selector(enableLocation(button:)), for: .touchUpInside)
        actionButton.snp.makeConstraints { (make) in
            make.left.equalTo(self).inset(leftRight)
            make.top.equalTo(descriptionLabel.snp.bottom).inset(-26)
            make.height.equalTo(48)
            make.bottom.equalTo(self).inset(24)
        }
    }

    @objc func enableLocation(button: UIButton) {
        if MunchLocation.isEnabled {
            self.controller.reset()
        } else {
            MunchLocation.request(force: true, permission: true)
                    .subscribe { event in
                        switch event {
                        case .success:
                            self.controller.reset()

                        case .error(let error):
                            self.controller.alert(error: error)
                        }
                    }
                    .disposed(by: disposeBag)
        }
    }

    override class var cardId: String {
        return "NoLocation_2017-10-20"
    }
}

class SearchNoResultCard: SearchCardView {
    private let titleImage = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = UIButton()

    override func didLoad(card: SearchCard) {
        self.addSubview(titleImage)
        self.addSubview(titleLabel)
        self.addSubview(descriptionLabel)

        titleLabel.text = "No Results".localized()
        titleLabel.font = UIFont.systemFont(ofSize: 22.0, weight: .semibold)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.72)
        titleLabel.numberOfLines = 0
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(topBottom)
        }

        descriptionLabel.text = "We could not find anything. Try broadening your search?".localized()
        descriptionLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        descriptionLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(titleLabel.snp.bottom).inset(-20)
            make.bottom.equalTo(self).inset(24)
        }
    }

    override class var cardId: String {
        return "NoResult_2017-12-08"
    }
}