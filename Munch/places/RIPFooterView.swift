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
            if place != nil {
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
            maker.right.equalTo(self).inset(16)
            maker.top.equalTo(self).inset(4)
            maker.bottom.equalTo(self.safeArea.bottom).inset(4)
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
    private let heartBtn = PlaceHeartButton()
    private var controller: UIViewController!
    private var place: Place!
    private let disposeBag = DisposeBag()

    required init() {
        super.init(frame: .zero)
        self.addSubview(heartBtn)

        heartBtn.isUserInteractionEnabled = false
        heartBtn.tintColor = UIColor.black
        heartBtn.isHidden = false
        heartBtn.snp.makeConstraints { maker in
            maker.edges.equalTo(self)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = 3.0
    }

    func register(place: Place, savedPlace: UserSavedPlace?, controller: UIViewController) {
        self.heartBtn.isSelected = savedPlace != nil

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
            guard case .loggedIn = state else {
                return
            }

            let generator = UIImpactFeedbackGenerator()

            if self.heartBtn.isSelected {
                PlaceSavedDatabase.shared.delete(placeId: place.placeId).subscribe { (event: SingleEvent<Bool>) in
                    switch event {
                    case .success:
                        self.heartBtn.isSelected = false
                        generator.impactOccurred()
                        view.makeToast("Removed '\(place.name)' from your places.")

                    case .error(let error):
                        self.controller.alert(error: error)
                    }
                }.disposed(by: self.disposeBag)
            } else {
                PlaceSavedDatabase.shared.put(placeId: place.placeId).subscribe { (event: SingleEvent<Bool>) in
                    switch event {
                    case .success:
                        self.heartBtn.isSelected = true
                        generator.impactOccurred()
                        view.makeToast("Added '\(place.name)' to your places.")

                    case .error(let error):
                        self.controller.alert(error: error)
                    }
                }.disposed(by: self.disposeBag)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}