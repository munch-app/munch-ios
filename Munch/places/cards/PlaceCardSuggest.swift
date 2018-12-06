////
//// Created by Fuxing Loh on 19/2/18.
//// Copyright (c) 2018 Munch Technologies. All rights reserved.
////
//
//import Foundation
//import UIKit
//import SafariServices
//
//import SnapKit
//
//class PlaceSuggestEditCard: PlaceCardView, SFSafariViewControllerDelegate {
//    let separatorLine = UIView()
//    let button: UIButton = {
//        let button = UIButton()
//        button.setTitle("Suggest Edits".localized(), for: .normal)
//        button.setTitleColor(UIColor.black.withAlphaComponent(0.85), for: .normal)
//        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
//        button.isUserInteractionEnabled = false
//
//        button.setImage(UIImage(named: "RIP-Pencil"), for: .normal)
//        button.tintColor = UIColor.black.withAlphaComponent(0.85)
//        button.imageEdgeInsets.right = 12
//        return button
//    }()
//
//    required init(card: PlaceCard, controller: PlaceController) {
//        super.init(card: card, controller: controller)
//        self.addSubview(separatorLine)
//        self.addSubview(button)
//
//        separatorLine.backgroundColor = UIColor(hex: "d5d4d8")
//        separatorLine.snp.makeConstraints { make in
//            make.left.right.equalTo(self)
//            make.top.equalTo(self).inset(topSeparator)
//            make.height.equalTo(1.0 / UIScreen.main.scale)
//        }
//
//        button.snp.makeConstraints { make in
//            make.left.right.equalTo(self)
//            make.top.equalTo(separatorLine.snp.bottom).inset(-topBottom + -topSeparator)
//            make.bottom.equalTo(self).inset(topBottom)
//        }
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    private var placeId: String?
//    private var name: String?
//    private var address: String?
//
//    override func didLoad(card: PlaceCard) {
//        self.placeId = card.string(name: "placeId")
//        self.name = card.string(name: "name")
//        self.address = card.string(name: "address")
//    }
//
//    override func didTap() {
//        self.controller.apply(click: .suggestEdit)
//    }
//
//    override class var cardId: String? {
//        return "ugc_SuggestEdit_20180428"
//    }
//}