//
// Created by Fuxing Loh on 2019-03-11.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class SearchCardClaimVoucher: SearchCardView {
    private let bannerImage: SizeImageView = {
        let imageView = SizeShimmerImageView(points: width, height: 1)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 3
        return imageView
    }()


    // 640 x 400
    override func didLoad(card: SearchCard) {
        self.addSubview(bannerImage) { maker in
            maker.left.width.equalTo(self).inset(leftRight)
            maker.top.bottom.equalTo(self).inset(topBottom)
            maker.height.equalTo(bannerImage.snp.width).multipliedBy(0.625).priority(.high)
        }
    }

    override func willDisplay(card: SearchCard) {
        if let image = card.decode(name: "image", Image.self) {
            bannerImage.render(image: image)
        }
    }

    override func didSelect(card: SearchCard, controller: SearchController) {
        Authentication.requireAuthentication(controller: self.controller) { state in
            guard case .loggedIn = state else {
                return
            }

            guard let voucherId = card.string(name: "voucherId") else {
                return
            }

            MunchAnalytic.logEvent("voucher_claim_show", parameters: [
                "voucherId": voucherId as NSObject,
                "from": "search_card" as NSObject,
            ]);


            let controller = VoucherPageController(voucherId: voucherId)
            self.controller.navigationController?.pushViewController(controller, animated: true)
        }
    }

    override class var cardId: String {
        return "ClaimVoucher_2019-03-11"
    }
}