//
// Created by Fuxing Loh on 2019-02-17.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import RxSwift
import RxCocoa

import Moya
import Toast_Swift

class LocationSelectSaveController: MHViewController {
    private let headerView = MHHeaderView()
            .with(title: "Add to Saved Locations")

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.contentInsetAdjustmentBehavior = .never
        view.alwaysBounceHorizontal = false
        return view
    }()
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        return stackView
    }()
    private let homeButton = SearchLocationSaveAsButton(icon: UIImage(named: "Location_Home"), text: "Home")
    private let workButton = SearchLocationSaveAsButton(icon: UIImage(named: "Location_Work"), text: "Work")
    private let savedButton = SearchLocationSaveAsButton(icon: UIImage(named: "Location_Bookmark_Filled"), text: "Others")

    private let bottomButton = MunchButton(style: .secondaryOutline)
            .with(text: "Save Location")

    private let userLocation: UserLocation
    private var selectedType: UserLocation.LocationType?

    private let userService = MunchProvider<UserLocationService>()

    init(userLocation: UserLocation) {
        self.userLocation = userLocation
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white

        self.view.addSubview(headerView)
        self.view.addSubview(bottomButton)

        self.headerView.backButton.addTarget(self, action: #selector(onBackButton), for: .touchUpInside)

        self.view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        self.headerView.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(self.view)
        }

        self.bottomButton.snp.makeConstraints { maker in
            maker.left.right.equalTo(self.view).inset(24)
            maker.bottom.equalTo(self.view.safeArea.bottom).inset(12)
        }

        self.scrollView.snp.makeConstraints { maker in
            maker.left.right.equalTo(self.view)
            maker.top.equalTo(self.headerView.snp.bottom)
            maker.bottom.equalTo(self.bottomButton.snp.top)
        }

        self.stackView.snp.makeConstraints { maker in
            maker.edges.equalTo(scrollView)
            maker.width.equalTo(scrollView.snp.width)
        }

        stackView.addArrangedSubview(
                PaddingWidget(top: 24, left: 24, right: 24, view: UILabel(style: .h6).with(text: "Name:")).view
        )
        stackView.addArrangedSubview(
                PaddingWidget(top: 2, bottom: 12, left: 24, right: 24, view: UILabel(style: .h4).with(text: userLocation.name)).view
        )

        stackView.addArrangedSubview(
                PaddingWidget(left: 24, right: 24, view: UILabel(style: .h6).with(text: "Save as")).view
        )

        stackView.addArrangedSubview(
                PaddingWidget(h: 24, v: 8, view: homeButton).view
        )
        stackView.addArrangedSubview(
                PaddingWidget(h: 24, v: 8, view: workButton).view
        )
        stackView.addArrangedSubview(
                PaddingWidget(h: 24, v: 8, view: savedButton).view
        )

        homeButton.addTarget(self, action: #selector(onButtonUp(button:)), for: .touchUpInside)
        workButton.addTarget(self, action: #selector(onButtonUp(button:)), for: .touchUpInside)
        savedButton.addTarget(self, action: #selector(onButtonUp(button:)), for: .touchUpInside)
        bottomButton.addTarget(self, action: #selector(onSave), for: .touchUpInside)
    }

    @objc func onButtonUp(button: UIButton) {
        self.homeButton.isSelected = false
        self.workButton.isSelected = false
        self.savedButton.isSelected = false

        self.bottomButton.with(style: .secondary)

        if (button == homeButton) {
            self.homeButton.isSelected = true
            self.selectedType = .home
        } else if (button == workButton) {
            self.selectedType = .work
            self.workButton.isSelected = true
        } else {
            self.selectedType = .saved
            self.savedButton.isSelected = true
        }
    }

    @objc func onSave() {
        guard let type = self.selectedType else {
            self.alert(title: "Type Required", message: "You need to select a type to save as.")
            return
        }

        guard Authentication.isAuthenticated() else {
            return
        }

        var location = UserLocation.new(
                type: type,
                input: userLocation.input,
                name: userLocation.name,
                latLng: userLocation.latLng
        )

        self.view.makeToastActivity(.center)
        userService.rx.request(.post(location)).subscribe { event in
            self.view.hideToastActivity()

            switch event {
            case .success:
                self.navigationController?.popViewController(animated: true)

            case let .error(error):
                self.alert(error: error)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MunchAnalytic.setScreen("/search/locations/save")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchLocationSaveAsButton: UIControl {
    private let imageView = UIImageView()
    private let label = UILabel(style: .regular)
            .with(font: .systemFont(ofSize: 17, weight: .medium))
            .with(numberOfLines: 1)

    init(icon: UIImage?, text: String) {
        super.init(frame: .zero)
        self.imageView.tintColor = .black
        self.imageView.image = icon
        self.label.text = text

        self.addSubview(imageView)
        self.addSubview(label)

        self.backgroundColor = .whisper100
        self.layer.cornerRadius = 3.0

        self.imageView.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self).inset(12)
            maker.left.equalTo(self).inset(16)
            maker.width.height.equalTo(24)
        }

        self.label.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self)
            maker.right.equalTo(self).inset(16)
            maker.left.equalTo(self.imageView.snp.right).inset(-16)
        }
        self.isSelected = false
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                self.backgroundColor = .secondary400
                self.imageView.tintColor = .white
                self.label.textColor = .white
            } else {
                self.backgroundColor = .whisper100
                self.imageView.tintColor = .black
                self.label.textColor = .black
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}