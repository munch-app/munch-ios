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
import FirebaseAnalytics

class SearchNoLocationCard: UITableViewCell, SearchCardView {
    private let titleImage = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = UIButton()

    private var delegate: SearchTableViewDelegate!
    private var disposeBag = DisposeBag()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(titleImage)
        self.addSubview(titleLabel)
        self.addSubview(descriptionLabel)
        self.addSubview(actionButton)

        titleLabel.text = "No Location".localized()
        titleLabel.font = UIFont.systemFont(ofSize: 22.0, weight: .semibold)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.72)
        titleLabel.backgroundColor = .white
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(topBottom)
        }

        descriptionLabel.text = "You have turned off your location service. Turn it on for better suggestion?".localized()
        descriptionLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        descriptionLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.backgroundColor = .white
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(titleLabel.snp.bottom).inset(-20)
        }

        actionButton.layer.cornerRadius = 3
        actionButton.backgroundColor = .primary500
        actionButton.setTitle("Enable Location".localized(), for: .normal)
        actionButton.contentEdgeInsets.left = 32
        actionButton.contentEdgeInsets.right = 32
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel!.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        actionButton.snp.makeConstraints { (make) in
            make.left.equalTo(self).inset(leftRight)
            make.top.equalTo(descriptionLabel.snp.bottom).inset(-26)
            make.height.equalTo(48)
            make.bottom.equalTo(self).inset(24)
        }
        actionButton.addTarget(self, action: #selector(enableLocation(button:)), for: .touchUpInside)
    }

    @objc func enableLocation(button: UIButton) {
        if MunchLocation.isEnabled {
//            controller.reset(force: true)
        } else {
            Analytics.logEvent("enable_location", parameters: [:])
            MunchLocation.requestLocation()
                    .subscribe { event in
                        switch event {
                        case .success:
                            self.actionButton.setTitle("Refresh Search", for: .normal)
                            self.actionButton.backgroundColor = .secondary500

                        case .error(let error):
                            self.delegate.searchTableView { controller in
                                controller.alert(error: error)
                            }
                        }
                    }
                    .disposed(by: disposeBag)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, delegate: SearchTableViewDelegate) {
        self.delegate = delegate
    }

    static var cardId: String {
        return "injected_NoLocation_20171020"
    }
}

class SearchNoResultCard: UITableViewCell, SearchCardView {
    private let titleImage = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = UIButton()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, delegate: SearchTableViewDelegate) {
    }

    static var cardId: String {
        return "injected_NoResult_20171208"
    }
}

class SearchNoResultLocationCard: UITableViewCell, SearchCardView {
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = UIButton()

    private var searchQuery: SearchQuery!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(titleLabel)
        self.addSubview(descriptionLabel)

        titleLabel.text = "No Results found 'Nearby'".localized()
        titleLabel.font = UIFont.systemFont(ofSize: 22.0, weight: .semibold)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.72)
        titleLabel.numberOfLines = 0
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(topBottom)
        }

        descriptionLabel.text = "We could not find results in 'Nearby' here are results for 'Anywhere'".localized()
        descriptionLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        descriptionLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(titleLabel.snp.bottom).inset(-20)
            make.bottom.equalTo(self).inset(topBottom)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, delegate: SearchTableViewDelegate) {
        if let locationName = card.string(name: "locationName") {
            let title = "No Results in".localized()
            titleLabel.text = "\(title) '\(locationName)'"
            // We couldn't find results in "Nearby". Here are the results for "Anywhere".
            let prefix = "We could not find results in '".localized()
            let postfix = "'. Here are the results for 'Anywhere'".localized()
            descriptionLabel.text = "\(prefix)\(locationName)'\(postfix)"
        } else {
            titleLabel.text = "No Results found 'Nearby'".localized()
            descriptionLabel.text = "We could not find results in 'Nearby' here are results for 'Anywhere'".localized()
        }
    }

    static var cardId: String {
        return "injected_NoResultLocation_20171208"
    }
}