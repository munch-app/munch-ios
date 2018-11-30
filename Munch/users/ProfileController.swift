////
//// Created by Fuxing Loh on 19/6/18.
//// Copyright (c) 2018 Munch Technologies. All rights reserved.
////
//
import Foundation
import UIKit
//import Localize_Swift
//import RxSwift
//
//import SnapKit
//import NVActivityIndicatorView
//
class ProfileRootController: UINavigationController, UINavigationControllerDelegate {
    let controller = UIViewController()

    required init() {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [controller]
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
//
//class ProfileController: UIViewController {
//    let headerView = ProfileHeaderView()
//    let collectionView: UICollectionView = initCollection()
//
//    let collectionDatabase = UserPlaceCollectionDatabase()
//    let disposeBag = DisposeBag()
//    var items: [ProfileTabDataType] = [.loading]
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        // Make navigation bar transparent, bar must be hidden
//        navigationController?.setNavigationBarHidden(true, animated: false)
//        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
//        navigationController?.navigationBar.shadowImage = UIImage()
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        self.headerView.render()
//
//        if Authentication.isAuthenticated() {
//            self.headerView.render()
//            self.collectionView.reloadData()
//            self.collectionDatabase.sendLocal()
//        } else {
//            self.tabBarController?.selectedIndex = 0
//        }
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.initViews()
//        self.initTabs()
//        self.initObserver()
//
//        self.headerView.render()
//        self.headerView.settingButton.addTarget(self, action: #selector(onActionSetting(_:)), for: .touchUpInside)
//        for tabButton in self.headerView.tabButtons {
//            tabButton.addTarget(self, action: #selector(onActionSelectTab(selected:)), for: .touchUpInside)
//        }
//    }
//
//    func initViews() {
//        self.view.addSubview(collectionView)
//        self.view.addSubview(headerView)
//        self.view.backgroundColor = .white
//
//        headerView.snp.makeConstraints { make in
//            make.top.left.right.equalTo(self.view)
//        }
//
//        collectionView.snp.makeConstraints { make in
//            make.edges.equalTo(self.view)
//        }
//    }
//
//    @objc func onActionSetting(_ sender: Any) {
//        navigationController?.pushViewController(ProfileSettingController(), animated: true)
//    }
//
//    @objc fileprivate func onActionSelectTab(selected: ProfileTabButton) {
//        self.collectionView.reloadData()
//    }
//}
//
//class ProfileHeaderView: UIView {
//    let layerOne: UIView = {
//        let view = UIView()
//        view.backgroundColor = .white
//        return view
//    }() // Image & Setting
//    let layerTwo: UIView = {
//        let view = UIView()
//        view.backgroundColor = .white
//        return view
//    }() // Profile Details
//    let layerThree: UIView = {
//        let view = UIView()
//        view.backgroundColor = .white
//        return view
//    }() // Tab Bar
//    fileprivate var topConstraint: Constraint! = nil
//
//    let settingButton: UIButton = {
//        let button = UIButton()
//        button.setImage(UIImage(named: "NavigationBar-Setting"), for: .normal)
//        button.tintColor = .black
//        button.contentHorizontalAlignment = .right
//        button.imageEdgeInsets.right = 24
//        return button
//    }()
//
//    let profileImageView: SizeImageView = {
//        let imageView = SizeImageView(points: 22, height: 22)
//        imageView.layer.cornerRadius = 22
//
//        imageView.backgroundColor = UIColor(hex: "F0F0F0")
//        imageView.clipsToBounds = true
//        return imageView
//    }()
//
//    let nameLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 22, weight: .medium)
//        label.numberOfLines = 1
//        return label
//    }()
//    let emailLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 13, weight: .regular)
//        return label
//    }()
//
//    fileprivate let tabButtons = [
//        ProfileTabButton(type: .collections)
//    ]
//    fileprivate var selectedType: ProfileTabType {
//        for button in tabButtons {
//            if button.isTabSelected {
//                return button.type
//            }
//        }
//        return ProfileTabType.collections
//    }
//
//    override init(frame: CGRect = CGRect.zero) {
//        super.init(frame: frame)
//        self.initViews()
//
//        tabButtons[0].isTabSelected = true
//        for tab in tabButtons {
//            tab.addTarget(self, action: #selector(onSelectTab(selected:)), for: .touchUpInside)
//        }
//    }
//
//    private func initViews() {
//        self.backgroundColor = .white
//        layerOne.addSubview(profileImageView)
//        layerOne.addSubview(settingButton)
//
//        layerTwo.addSubview(nameLabel)
//        layerTwo.addSubview(emailLabel)
//
//        for tab in tabButtons {
//            layerThree.addSubview(tab)
//        }
//
//        self.addSubview(layerTwo)
//        self.addSubview(layerOne)
//        self.addSubview(layerThree)
//
//        layerOne.snp.makeConstraints { make in
//            make.top.equalTo(self)
//            make.left.right.equalTo(self)
//        }
//
//        settingButton.snp.makeConstraints { make in
//            make.right.equalTo(layerOne)
//            make.top.equalTo(self.safeArea.top)
//            make.bottom.equalTo(layerOne)
//            make.width.equalTo(64)
//        }
//
//        profileImageView.snp.makeConstraints { make in
//            make.left.equalTo(layerOne).inset(24)
//            make.top.equalTo(self.safeArea.top)
//            make.bottom.equalTo(layerOne)
//            make.width.height.equalTo(44)
//        }
//
//        layerTwo.snp.makeConstraints { make in
//            self.topConstraint = make.top.equalTo(layerOne.snp.bottom).constraint
//            make.left.right.equalTo(self)
//            make.height.equalTo(55)
//        }
//
//        nameLabel.snp.makeConstraints { make in
//            make.left.right.equalTo(layerTwo).inset(24)
//            make.top.equalTo(layerTwo).inset(10)
//        }
//
//        emailLabel.snp.makeConstraints { make in
//            make.left.right.equalTo(layerTwo).inset(24)
//            make.top.equalTo(nameLabel.snp.bottom).inset(-3)
//        }
//
//        layerThree.snp.makeConstraints { make in
//            make.top.equalTo(layerTwo.snp.bottom)
//            make.left.right.equalTo(self)
//            make.bottom.equalTo(self)
//            make.height.equalTo(40)
//        }
//
//        // Setup Profile Tabs
//        var leftOfTab: UIView? = nil
//        for tab in tabButtons {
//            tab.snp.makeConstraints { make in
//                make.top.bottom.equalTo(layerThree)
//                if let left = leftOfTab {
//                    make.left.equalTo(left).inset(-24)
//                } else {
//                    make.left.equalTo(layerThree).inset(24)
//                }
//                leftOfTab = tab
//            }
//        }
//    }
//
//    func render() {
//        let profile = UserProfile.instance
//        self.profileImageView.render(url: profile?.photoUrl)
//        self.nameLabel.text = profile?.name
//        self.emailLabel.text = profile?.email
//    }
//
//    @objc fileprivate func onSelectTab(selected: ProfileTabButton) {
//        for tabButton in tabButtons {
//            if tabButton == selected {
//                tabButton.isTabSelected = true
//            } else {
//                tabButton.isTabSelected = false
//            }
//        }
//    }
//
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        self.hairlineShadow(height: 1.0)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
//
//// Header Scroll to Hide Functions
//extension ProfileHeaderView {
//    var contentHeight: CGFloat {
//        return 55 + 40 + 44
//    }
//
//    var maxHeight: CGFloat {
//        // contentHeight + safeArea.top
//        return self.safeAreaInsets.top + contentHeight
//    }
//
//    func contentDidScroll(scrollView: UIScrollView) {
//        let offset = calculateOffset(scrollView: scrollView)
//        self.topConstraint.update(inset: offset)
//    }
//
//    /**
//     nil means don't move
//     */
//    func contentShouldMove(scrollView: UIScrollView) -> CGFloat? {
//        let offset = calculateOffset(scrollView: scrollView)
//
//        // Already fully closed or opened
//        if (offset == 55.0 || offset == 0.0) {
//            return nil
//        }
//
//
//        if (offset < 28) {
//            // To close
//            return -maxHeight + 55
//        } else {
//            // To open
//            return -maxHeight
//        }
//    }
//
//    private func calculateOffset(scrollView: UIScrollView) -> CGFloat {
//        let y = scrollView.contentOffset.y
//
//        if y <= -maxHeight {
//            return 0
//        } else if y >= -maxHeight + 55 {
//            return 55
//        } else {
//            return (maxHeight + y)
//        }
//    }
//}
//
//fileprivate enum ProfileTabType: String {
//    case collections
//    case reviews
//    case munches
//
//    var title: String {
//        switch self {
//        case .collections:
//            return "COLLECTIONS".localized()
//        case .reviews:
//            return "REVIEWS".localized()
//        case .munches:
//            return "MUNCHES".localized()
//        }
//    }
//}
//
//fileprivate class ProfileTabButton: UIButton {
//    private let nameLabel: UILabel = {
//        let nameLabel = UILabel()
//        nameLabel.backgroundColor = .clear
//        nameLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .semibold)
//        nameLabel.textColor = UIColor.black.withAlphaComponent(0.85)
//
//        nameLabel.numberOfLines = 1
//        nameLabel.isUserInteractionEnabled = false
//
//        nameLabel.textAlignment = .left
//        return nameLabel
//    }()
//    private let indicatorView: UIView = {
//        let view = UIView()
//        view.backgroundColor = UIColor.primary500
//        return view
//    }()
//
//    let type: ProfileTabType
//
//    init(type: ProfileTabType) {
//        self.type = type
//        super.init(frame: .zero)
//        self.addSubview(nameLabel)
//        self.addSubview(indicatorView)
//
//        nameLabel.text = type.title
//        nameLabel.snp.makeConstraints { make in
//            make.left.right.equalTo(self)
//            make.top.equalTo(self).inset(13)
//        }
//
//        indicatorView.snp.makeConstraints { make in
//            make.left.right.equalTo(self)
//            make.bottom.equalTo(self)
//            make.height.equalTo(2)
//        }
//    }
//
//    var isTabSelected: Bool {
//        get {
//            return !self.indicatorView.isHidden
//        }
//
//        set(value) {
//            self.indicatorView.isHidden = !value
//        }
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}