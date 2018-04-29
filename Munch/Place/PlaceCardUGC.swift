//
// Created by Fuxing Loh on 19/2/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

import SwiftyJSON
import SnapKit
import TTGTagCollectionView

import FirebaseAnalytics

class PlaceHeaderUGCCard: PlaceTitleCardView {
    override func didLoad(card: PlaceCard) {
        self.title = "Experimental Tags"
    }

    override class var cardId: String? {
        return "header_UGC_20180219"
    }
}

class PlaceSuggestEditCard: PlaceCardView, SFSafariViewControllerDelegate {
    let separatorLine = UIView()
    let button: UIButton = {
        let button = UIButton()
        button.setTitle("Suggest an edit", for: .normal)
        button.setTitleColor(UIColor.primary600, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        button.isUserInteractionEnabled = false
        return button
    }()

    required init(card: PlaceCard, controller: PlaceViewController) {
        super.init(card: card, controller: controller)
        self.addSubview(separatorLine)
        self.addSubview(button)

        separatorLine.backgroundColor = UIColor(hex: "d5d4d8")
        separatorLine.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self).inset(15)
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }

        button.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(separatorLine.snp.bottom).inset(-topBottom)
            make.bottom.equalTo(self).inset(topBottom)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var placeId: String?
    private var name: String?
    private var address: String?

    override func didLoad(card: PlaceCard) {
        self.placeId = card["placeId"].string
        self.name = card["name"].string?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        self.address = card["address"].string?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
    }

    override func didTap() {
        AccountAuthentication.requireAuthentication(controller: self.controller) { state in
            switch state {
            case .loggedIn:
                let urlComps = NSURLComponents(string: "https://airtable.com/shrfxcHiCwlSl1rjk")!
                urlComps.queryItems = [
                    URLQueryItem(name: "prefill_Place.id", value: self.placeId),
                    URLQueryItem(name: "prefill_Place.status", value: "Open"),
                    URLQueryItem(name: "prefill_Place.name", value: self.name),
                    URLQueryItem(name: "prefill_Place.Location.address", value: self.address)
                ]
                let safari = SFSafariViewController(url: urlComps.url!)
                safari.delegate = self
                self.controller.present(safari, animated: true, completion: nil)

                Analytics.logEvent("rip_action", parameters: [
                    AnalyticsParameterItemCategory: "click_suggest_edit" as NSObject
                ])
            default:
                return
            }
        }
    }

    override class var cardId: String? {
        return "ugc_SuggestEdit_20180428"
    }
}