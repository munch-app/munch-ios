//
// Created by Fuxing Loh on 20/12/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import SafariServices

class RIPMenuWebsiteCard: RIPCard {
    let button = MunchButton(style: .border)
            .with(text: "Website Menu")
    var url: URL?

    override func didLoad(data: PlaceData!) {
        self.addSubview(button)
        self.addTargets()

        button.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self).inset(12)
            maker.left.equalTo(self).inset(24)
            maker.right.lessThanOrEqualTo(self).inset(24)
        }

        self.url = URL(string: data.place.menu!.url!)
    }

    override class func isAvailable(data: PlaceData) -> Bool {
        return data.place.menu?.url != nil
    }
}

extension RIPMenuWebsiteCard: SFSafariViewControllerDelegate {
    func addTargets() {
        button.addTarget(self, action: #selector(onCall), for: .touchUpInside)
    }

    @objc func onCall() {
        guard let url = url else {
            return
        }

        let safari = SFSafariViewController(url: url)
        safari.delegate = self
        controller.present(safari, animated: true, completion: nil)
    }
}