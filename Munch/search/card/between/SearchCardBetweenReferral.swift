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
        view.backgroundColor = .primary500
        return view
    }()
    private let headerLabel = UILabel(style: .h3)
            .with(numberOfLines: 0)
            .with(text: "Share search results with your friends")
            .with(color: .white)
    private let shareBtn = MunchButton(style: .primaryOutline)
            .with(text: "SHARE")

    override func didLoad(card: SearchCard) {
        self.addSubview(cardView)
        cardView.addSubview(shareBtn)
        cardView.addSubview(headerLabel)

        cardView.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.bottom.equalTo(self).inset(topBottom)
        }

        headerLabel.snp.makeConstraints { maker in
            maker.top.equalTo(cardView).inset(16)
            maker.left.right.equalTo(cardView).inset(20)
            maker.bottom.equalTo(shareBtn.snp.top).inset(-16)
        }
        
        shareBtn.snp.makeConstraints { maker in
            maker.bottom.equalTo(cardView).inset(16)
            maker.right.equalTo(cardView).inset(20)
        }

        self.shareBtn.addTarget(self, action: #selector(onShare), for: .touchUpInside)
    }

    override class func height(card: SearchCard) -> CGFloat {
        let paddedWidth = contentWidth - 48

        return topBottom +
                16 +
                FontStyle.h2.height(text: "Share search results with your friends", width: paddedWidth) +
                16 +
                MunchButtonStyle.secondaryOutline.height +
                16 +
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