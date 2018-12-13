//
// Created by Fuxing Loh on 2018-12-05.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import RxSwift

import Toast_Swift

class RIPFooterView: UIView {
    let addButton = AddPlaceButton()

    var place: Place? {
        didSet {
            if let place = place {
                self.setHidden(isHidden: false)
            } else {
                self.setHidden(isHidden: true)
            }
        }
    }

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.setHidden(isHidden: true)

        self.addSubview(addButton)

        addButton.snp.makeConstraints { maker in
            maker.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(10)
            maker.bottom.equalTo(self.safeArea.bottom).inset(10)
        }
    }

    private func setHidden(isHidden: Bool) {
        addButton.isHidden = isHidden
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: -1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AddPlaceButton: UIButton {
    private let nameLabel = UILabel()
            .with(alignment: .center)
            .with(numberOfLines: 1)
            .with(text: "Add Place")

    private var controller: UIViewController!
    private var place: Place!
    private let disposeBag = DisposeBag()

    required init() {
        super.init(frame: .zero)
        self.addSubview(nameLabel)

        self.backgroundColor = .secondary500
        self.nameLabel.textColor = .white
        self.nameLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)

        snp.makeConstraints { maker in
            maker.height.equalTo(36)
        }

        nameLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(self)
            maker.left.right.equalTo(self).inset(18)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = 3.0
    }

    func register(place: Place, controller: UIViewController) {
        self.place = place
        self.controller = controller
        self.addTarget(self, action: #selector(onAddPlace), for: .touchUpInside)
    }

    @objc private func onAddPlace() {
        guard let place = self.place else {
            return
        }
        guard let view = self.controller.view else {
            return
        }

        Authentication.requireAuthentication(controller: controller) { state in
            PlaceSavedDatabase.shared.toggle(placeId: place.placeId).subscribe { (event: SingleEvent<Bool>) in
                let generator = UIImpactFeedbackGenerator()

                switch event {
                case .success(let added):
                    generator.impactOccurred()
                    if added {
                        view.makeToast("Added '\(place.name)' to your places.")
                    } else {
                        view.makeToast("Removed '\(place.name)' from your places.")
                    }

                case .error(let error):
                    generator.impactOccurred()
                    self.controller.alert(error: error)
                }
            }.disposed(by: self.disposeBag)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}