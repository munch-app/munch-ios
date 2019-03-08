//
// Created by Fuxing Loh on 2018-12-05.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import SafariServices

class RIPHeaderView: UIView {
    private let backButton: UIButton = {
        let button = UIButton()
        button.isUserInteractionEnabled = false
        button.setImage(UIImage(named: "NavigationBar-Back"), for: .normal)
        button.tintColor = .white
        button.imageEdgeInsets.left = 18
        button.contentHorizontalAlignment = .left
        return button
    }()
    let backControl = UIControl()
    let moreBtn: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "RIP-Header-More"), for: .normal)
        button.tintColor = .white
        button.imageEdgeInsets.right = 24
        button.contentHorizontalAlignment = .right
        return button
    }()
    let titleView: UILabel = {
        let titleView = UILabel(style: .navHeader)
        return titleView
    }()

    var controller: UIViewController!
    let backgroundView = UIView()
    let shadowView = UIView()

    var place: Place? {
        didSet {
            if let place = place {
                self.titleView.text = place.name
            } else {
                self.titleView.text = nil
            }
        }
    }
    override var tintColor: UIColor! {
        didSet {
            self.backButton.tintColor = tintColor
            self.moreBtn.tintColor = tintColor
            self.titleView.textColor = tintColor
        }
    }

    init(tintColor: UIColor = .black, backgroundVisible: Bool = true, titleHidden: Bool = false) {
        super.init(frame: CGRect.zero)
        self.initViews()

        self.titleView.isHidden = titleHidden
        self.tintColor = tintColor

        self.backgroundView.backgroundColor = .white
        self.backgroundView.isHidden = !backgroundVisible
        self.shadowView.isHidden = !backgroundVisible
    }

    private func initViews() {
        self.backgroundColor = .clear
        self.backgroundView.backgroundColor = .clear

        self.addSubview(shadowView)
        self.addSubview(backgroundView)
        self.addSubview(moreBtn)

        backControl.addSubview(backButton)
        backControl.addSubview(titleView)
        self.addSubview(backControl)

        backControl.snp.makeConstraints { maker in
            maker.top.equalTo(self.safeArea.top)
            maker.left.bottom.equalTo(self)
            maker.right.lessThanOrEqualTo(moreBtn.snp.left).inset(-16)

            backButton.snp.makeConstraints { maker in
                maker.top.left.bottom.equalTo(backControl)

                maker.width.equalTo(52)
                maker.height.equalTo(44)
            }

            titleView.snp.makeConstraints { maker in
                maker.top.bottom.equalTo(backControl)
                maker.left.equalTo(backButton.snp.right)
                maker.right.equalTo(backControl)
            }
        }

        moreBtn.snp.makeConstraints { maker in
            maker.right.equalTo(self)
            maker.top.bottom.equalTo(backButton)
            maker.width.equalTo(56)
        }

        backgroundView.snp.makeConstraints { maker in
            maker.edges.equalTo(self)
        }

        shadowView.snp.makeConstraints { maker in
            maker.edges.equalTo(self)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shadowView.shadow(vertical: 2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension RIPHeaderView: SFSafariViewControllerDelegate {
    func addTargets(controller: UIViewController) {
        self.controller = controller
        self.moreBtn.addTarget(self, action: #selector(onMore), for: .touchUpInside)
    }

    @objc func onMore() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.view.tintColor = .black

        alert.addAction(UIAlertAction(title: "Suggest Edits", style: .default) { action in
            Authentication.requireAuthentication(controller: self.controller) { state in
                switch state {
                case .loggedIn:
                    self.onSuggestEdit()

                default:
                    return
                }
            }

        })
        alert.addAction(UIAlertAction(title: "Share", style: .default) { action in
            self.onShare()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        MunchAnalytic.logEvent("rip_click_more")
        controller.present(alert, animated: true)
    }

    @objc func onSuggestEdit() {
        RIPSuggestEditCard.onSuggestEdit(place: self.place, controller: self.controller, delegate: self)
    }

    @objc func onShare() {
        guard let place = self.place else {
            return
        }

        if let url = URL(string: "https://www.munch.app/places/\(place.placeId)") {
            let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            controller.excludedActivityTypes = [.airDrop, .addToReadingList, UIActivity.ActivityType.openInIBooks]
            MunchAnalytic.logEvent("rip_share")
            self.controller.present(controller, animated: true)
        }
    }
}