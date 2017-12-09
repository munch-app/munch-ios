//
// Created by Fuxing Loh on 9/12/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

import SnapKit
import SwiftyJSON

class PlaceHeaderInstagramCard: PlaceTitleCardView {
    override func didLoad(card: PlaceCard) {
        self.title = "Instagram"
    }

    override class var cardId: String? {
        return "header_Instagram_20171208"
    }
}

class PlaceVendorInstagramGridCard: PlaceCardView {
    let topRow = RowView()
    let bottomRow = RowView()

    override func didLoad(card: PlaceCard) {
        // Hide See More if < 4
        let medias = card.data.map({ InstagramMedia(json: $0.1) })
        super.addSubview(topRow)

        topRow.render(left: medias.get(0), right: medias.get(1), controller: controller)
        topRow.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(topBottom).priority(999)
        }

        if (medias.count > 3) {
            super.addSubview(bottomRow)
            bottomRow.render(left: medias.get(2), right: medias.get(3), controller: controller)
            bottomRow.snp.makeConstraints { (make) in
                make.left.right.equalTo(self).inset(leftRight)
                make.top.equalTo(topRow.snp.bottom).inset(-20).priority(999)
                make.bottom.equalTo(self).inset(topBottom).priority(999)
            }
        } else {
            topRow.snp.makeConstraints({ (make) in
                make.bottom.equalTo(self).inset(topBottom).priority(999)
            })
        }
    }

    override class var cardId: String? {
        return "vendor_InstagramMedia_20171204"
    }

    class RowView: UIView {
        let leftView = MediaView()
        let rightView = MediaView()

        override init(frame: CGRect) {
            super.init(frame: frame)
            self.addSubview(leftView)
            self.addSubview(rightView)

            leftView.snp.makeConstraints { (make) in
                make.top.bottom.equalTo(self).priority(999)
                make.right.equalTo(rightView.snp.left).inset(-20).priority(999)
                make.left.equalTo(self).priority(999)
                make.width.equalTo(rightView.snp.width).priority(999)
            }

            rightView.snp.makeConstraints { (make) in
                make.top.bottom.equalTo(self).priority(999)
                make.left.equalTo(leftView.snp.right).inset(-20).priority(999)
                make.right.equalTo(self).priority(999)
                make.width.equalTo(leftView.snp.width).priority(999)
            }
        }

        func render(left: InstagramMedia?, right: InstagramMedia?, controller: PlaceViewController) {
            leftView.render(media: left, controller: controller)
            rightView.render(media: right, controller: controller)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class MediaView: UIView, SFSafariViewControllerDelegate {
        let mediaImageView = ShimmerImageView()

        var media: InstagramMedia!
        var controller: PlaceViewController!

        override init(frame: CGRect) {
            super.init(frame: frame)
            self.addSubview(mediaImageView)

            mediaImageView.layer.cornerRadius = 2
            mediaImageView.snp.makeConstraints { (make) in
                make.left.right.equalTo(self)
                make.top.equalTo(self)
                make.width.equalTo(mediaImageView.snp.height).priority(999)
                make.bottom.equalTo(self)
            }

            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:))))
            self.isUserInteractionEnabled = true
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func render(media: InstagramMedia?, controller: PlaceViewController) {
            self.media = media
            self.controller = controller

            if let media = media {
                mediaImageView.render(images: media.images)
            } else {
                self.isHidden = true
            }
        }

        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            if let mediaId = media.mediaId, let url = URL(string: "instagram://media?id=\(mediaId)") {
                if (UIApplication.shared.canOpenURL(url)) {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
}