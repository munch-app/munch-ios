//
//  AccountController.swift
//  Munch
//
//  Created by Fuxing Loh on 23/10/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit

import NVActivityIndicatorView

class AccountController: UINavigationController, UINavigationControllerDelegate {
    required init() {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [AccountProfileController()]
        self.delegate = self
    }

    // Fix bug when pop gesture is enabled for the root controller
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        self.interactivePopGestureRecognizer?.isEnabled = self.viewControllers.count > 1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AccountProfileController: UIViewController {
    let headerView = AccountHeaderView()
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 18

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = UIColor.white
        return collectionView
    }()

    var loadedDate: Date?
    let dataLoader = UserAccountDataLoader()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.headerView.render()

        if Authentication.isAuthenticated() {
            if loadedDate == nil || loadedDate! != MunchApi.collections.changedDate {
                self.dataLoader.resetAll()
                self.collectionView.reloadData()
                loadedDate = MunchApi.collections.changedDate
            }
            return
        }

        // Check if user is logged in, push to AccountBoardingController if not
        // Only reload profile if is empty, to reduce network requests
        Authentication.requireAuthentication(controller: self) { state in
            switch state {
            case .loggedIn:
                // Reload HeaderView on load
                self.headerView.render()
                self.dataLoader.resetAll()
                self.collectionView.reloadData()
            default:
                // Change to first tab if failed
                self.tabBarController?.selectedIndex = 0
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()

        self.initAccountData()

        self.headerView.render()
        self.headerView.settingButton.addTarget(self, action: #selector(onActionSetting(_:)), for: .touchUpInside)

        self.headerView.likeTab.addTarget(self, action: #selector(onActionSelectTab(selected:)), for: .touchUpInside)
        self.headerView.collectionTab.addTarget(self, action: #selector(onActionSelectTab(selected:)), for: .touchUpInside)
    }

    func initViews() {
        self.view.addSubview(collectionView)
        self.view.addSubview(headerView)

        self.view.backgroundColor = .white

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }

        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    }

    @objc func onActionSetting(_ sender: Any) {
        navigationController?.pushViewController(AccountSettingController(), animated: true)
    }

    @objc fileprivate func onActionSelectTab(selected: AccountTabButton) {
        self.dataLoader.select(type: selected.name)
        self.collectionView.reloadData()
    }
}

class AccountHeaderView: UIView {
    let layerOne: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }() // Image & Setting
    let layerTwo: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }() // Profile Details
    let layerThree: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }() // Tab Bar

    let settingButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "NavigationBar-Setting"), for: .normal)
        button.tintColor = .black
        button.contentHorizontalAlignment = .right
        button.imageEdgeInsets.right = 24
        return button
    }()
    let profileImageView: MunchImageView = {
        let imageView = MunchImageView()
        imageView.backgroundColor = UIColor(hex: "F0F0F0")
        imageView.layer.cornerRadius = 22
        imageView.clipsToBounds = true
        return imageView
    }()

    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .medium)
        label.numberOfLines = 1
        return label
    }()
    let emailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        return label
    }()

    fileprivate let likeTab = AccountTabButton(name: "LIKES")
    fileprivate let collectionTab = AccountTabButton(name: "COLLECTIONS")
    fileprivate var topConstraint: Constraint! = nil
    var selectedType: String = "LIKES"

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.initViews()


        self.likeTab.addTarget(self, action: #selector(onSelectTab(selected:)), for: .touchUpInside)
        self.collectionTab.addTarget(self, action: #selector(onSelectTab(selected:)), for: .touchUpInside)
        self.onSelectTab(selected: likeTab)
    }

    private func initViews() {
        self.backgroundColor = .white
        layerOne.addSubview(profileImageView)
        layerOne.addSubview(settingButton)

        layerTwo.addSubview(nameLabel)
        layerTwo.addSubview(emailLabel)

        layerThree.addSubview(likeTab)
        layerThree.addSubview(collectionTab)

        self.addSubview(layerTwo)
        self.addSubview(layerOne)
        self.addSubview(layerThree)

        layerOne.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.left.right.equalTo(self)
        }

        settingButton.snp.makeConstraints { make in
            make.right.equalTo(layerOne)
            make.top.equalTo(self.safeArea.top)
            make.bottom.equalTo(layerOne)
            make.width.equalTo(64)
        }

        profileImageView.snp.makeConstraints { make in
            make.left.equalTo(layerOne).inset(24)
            make.top.equalTo(self.safeArea.top)
            make.bottom.equalTo(layerOne)
            make.width.height.equalTo(44)
        }

        layerTwo.snp.makeConstraints { make in
            self.topConstraint = make.top.equalTo(layerOne.snp.bottom).constraint
            make.left.right.equalTo(self)
            make.height.equalTo(55)
        }

        nameLabel.snp.makeConstraints { make in
            make.left.right.equalTo(layerTwo).inset(24)
            make.top.equalTo(layerTwo).inset(10)
        }

        emailLabel.snp.makeConstraints { make in
            make.left.right.equalTo(layerTwo).inset(24)
            make.top.equalTo(nameLabel.snp.bottom).inset(-3)
        }

        layerThree.snp.makeConstraints { make in
            make.top.equalTo(layerTwo.snp.bottom)
            make.left.right.equalTo(self)
            make.bottom.equalTo(self)
            make.height.equalTo(40)
        }

        likeTab.snp.makeConstraints { make in
            make.left.equalTo(layerThree).inset(24)
            make.top.equalTo(layerThree)
            make.bottom.equalTo(layerThree)
        }

        collectionTab.snp.makeConstraints { make in
            make.left.equalTo(likeTab.snp.right).inset(-24)
            make.top.equalTo(layerThree)
            make.bottom.equalTo(layerThree)
        }
    }

    func render() {
        if let pictureUrl = UserProfile.instance?.photoUrl {
            self.profileImageView.render(images: ["original": pictureUrl])
        }
        self.nameLabel.text = UserProfile.instance?.name
        self.emailLabel.text = UserProfile.instance?.email
    }

    @objc fileprivate func onSelectTab(selected: AccountTabButton) {
        likeTab.isTabSelected = false
        collectionTab.isTabSelected = false

        selectedType = selected.name
        selected.isTabSelected = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.hairlineShadow(height: 1.0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// Header Scroll to Hide Functions
extension AccountHeaderView {
    var contentHeight: CGFloat {
        return 55 + 40 + 44 // + 18 Because of top constraints
    }

    var maxHeight: CGFloat {
        // contentHeight + safeArea.top
        return self.safeAreaInsets.top + contentHeight
    }

    func contentDidScroll(scrollView: UIScrollView) {
        let offset = calculateOffset(scrollView: scrollView)
        self.topConstraint.update(inset: offset)
    }

    /**
     nil means don't move
     */
    func contentShouldMove(scrollView: UIScrollView) -> CGFloat? {
        let offset = calculateOffset(scrollView: scrollView)

        // Already fully closed or opened
        if (offset == 55.0 || offset == 0.0) {
            return nil
        }


        if (offset < 28) {
            // To close
            return -maxHeight + 55
        } else {
            // To open
            return -maxHeight
        }
    }

    private func calculateOffset(scrollView: UIScrollView) -> CGFloat {
        let y = scrollView.contentOffset.y

        if y <= -maxHeight {
            return 0
        } else if y >= -maxHeight + 55 {
            return 55
        } else {
            return (maxHeight + y)
        }
    }
}

fileprivate class AccountTabButton: UIButton {
    private let nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.backgroundColor = .clear
        nameLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .semibold)
        nameLabel.textColor = UIColor.black.withAlphaComponent(0.85)

        nameLabel.numberOfLines = 1
        nameLabel.isUserInteractionEnabled = false

        nameLabel.textAlignment = .left
        return nameLabel
    }()
    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.primary500
        return view
    }()
    let name: String

    init(name: String) {
        self.name = name
        super.init(frame: .zero)
        self.addSubview(nameLabel)
        self.addSubview(indicatorView)

        nameLabel.text = name

        nameLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self).inset(13)
        }

        indicatorView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.bottom.equalTo(self)
            make.height.equalTo(2)
        }
    }

    var isTabSelected: Bool {
        get {
            return !self.indicatorView.isHidden
        }

        set(value) {
            self.indicatorView.isHidden = !value
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}