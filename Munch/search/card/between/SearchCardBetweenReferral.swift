//
// Created by Fuxing Loh on 2019-02-13.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class SearchCardBetweenReferral: SearchCardView {
    private let cardView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.backgroundColor = .primary050
        return view
    }()
    private let headerLabel = UILabel(style: .h2)
            .with(numberOfLines: 0)
            .with(text: "Teamwork makes the dream work.")
    private let descriptionLabel = UILabel(style: .regular)
            .with(numberOfLines: 0)
            .with(text: "You've done the tough part now share this with your friends and ask somebody to pick.")
    private let shareBtn = MunchButton(style: .secondaryOutline)
            .with(text: "SHARE")

    override func didLoad(card: SearchCard) {
        self.addSubview(cardView)
        cardView.addSubview(shareBtn)
        cardView.addSubview(headerLabel)
        cardView.addSubview(descriptionLabel)

        cardView.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.bottom.equalTo(self).inset(topBottom)
        }

        headerLabel.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(cardView).inset(24)
        }

        descriptionLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(cardView).inset(24)
            maker.top.equalTo(headerLabel.snp.bottom).inset(-16)
            maker.bottom.equalTo(shareBtn.snp.top).inset(-24)
        }

        shareBtn.snp.makeConstraints { maker in
            maker.right.bottom.equalTo(cardView).inset(24)
        }

        self.shareBtn.addTarget(self, action: #selector(onShare), for: .touchUpInside)
    }

    override class func height(card: SearchCard) -> CGFloat {
        let paddedWidth = contentWidth - 48

        return topBottom +
                24 +
                FontStyle.h2.height(text: "Teamwork makes the dream work.", width: paddedWidth) +
                16 +
                FontStyle.regular.height(text: "You've done the tough part now share this with your friends and ask somebody to pick.", width: paddedWidth) +
                24 +
                MunchButtonStyle.secondaryOutline.height +
                24 +
                topBottom
    }

    @objc func onShare() {
        guard let qid = self.controller.qid else {
            return
        }

        if let url = URL(string: "https://www.munch.app/search?qid=\(qid)&g=GB10") {
            let controller = UIActivityViewController(activityItems: ["EatBetween", url], applicationActivities: nil)
            controller.excludedActivityTypes = [.airDrop, .addToReadingList, UIActivity.ActivityType.openInIBooks]

            MunchAnalytic.logSearchQueryShare(searchQuery: self.controller.searchQuery, trigger: "search_card_between_referral")
            self.controller.present(controller, animated: true)
        }
    }

    override class var cardId: String {
        return "BetweenReferral_2019-02-12"
    }
}