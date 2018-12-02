//
// Created by Fuxing Loh on 2018-12-01.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import Toast_Swift

class PlaceAddButton: UIButton {
    private let toastStyle: ToastStyle = {
        var style = ToastStyle()
        style.backgroundColor = UIColor.whisper100
        style.cornerRadius = 5
        style.imageSize = CGSize(width: 20, height: 20)
        style.fadeDuration = 6.0
        style.messageColor = UIColor.black.withAlphaComponent(0.85)
        style.messageFont = UIFont.systemFont(ofSize: 15, weight: .regular)
        style.messageNumberOfLines = 2
        style.messageAlignment = .left

        return style
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.setImage(UIImage(named: "RIP-Add"), for: .normal)
        self.tintColor = .white

        self.addTarget(self, action: #selector(onButton(_:)), for: .touchUpInside)
    }

    var controller: UIViewController?
    var place: Place?

    @objc func onButton(_ button: Any) {
        guard let controller = self.controller, let place = self.place else {
            return
        }

        Authentication.requireAuthentication(controller: controller) { state in
            switch state {
            case .loggedIn:
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                let controller = AddToCollectionController(place: place) { action in
                    switch action {
                    case .add(let collection):
                        if let placeController = self.controller as? RIPController {
                            placeController.apply(click: .addedToCollection)
                        }
                        self.controller?.makeToast("Added to \(collection.name)", image: .checkmark)

                    case .remove(let collection):
                        self.controller?.makeToast("Removed from \(collection.name)", image: .checkmark)

                    default:
                        return
                    }

                }
                self.controller?.present(controller, animated: true)
            default:
                return
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
