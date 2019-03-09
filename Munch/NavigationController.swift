//
// Created by Fuxing Loh on 2019-01-10.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import UIKit
import SnapKit

class MHNavigationController: UINavigationController, UINavigationControllerDelegate {

    init(controller: UIViewController) {
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

class MHViewController: UIViewController, UIGestureRecognizerDelegate {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    @objc public func onBackButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

class MHHeaderView: UIView {
    private let backBtn: UIButton = {
        let button = UIButton()
        button.isUserInteractionEnabled = true
        button.setImage(UIImage(named: "NavigationBar-Back"), for: .normal)
        button.tintColor = .black
        button.imageEdgeInsets.left = 18
        button.contentHorizontalAlignment = .left
        return button
    }()
    private let titleLabel: UILabel = {
        let titleView = UILabel(style: .navHeader)
                .with(alignment: .center)
        return titleView
    }()
    private let moreBtn: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Navigation_More"), for: .normal)
        button.tintColor = .black
        button.imageEdgeInsets.right = 24
        button.contentHorizontalAlignment = .right
        return button
    }()
    private let backgroundView = UIView()
    private let shadowView = UIView()

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.backgroundView.backgroundColor = .white

        self.addSubview(shadowView)
        self.addSubview(backgroundView)

        self.addSubview(backBtn)
        self.addSubview(titleLabel)
        self.addSubview(moreBtn)

        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(52)
            maker.height.equalTo(44)

            maker.top.equalTo(self.safeArea.top)
            maker.bottom.equalTo(self)
        }

        backBtn.isHidden = true
        backBtn.snp.makeConstraints { maker in
            maker.top.equalTo(self.safeArea.top)
            maker.bottom.equalTo(self)

            maker.left.equalTo(self)
            maker.width.equalTo(52)
            maker.height.equalTo(44)
        }

        moreBtn.isHidden = true
        moreBtn.snp.makeConstraints { maker in
            maker.top.equalTo(self.safeArea.top)
            maker.bottom.equalTo(self)

            maker.right.equalTo(self)
            maker.top.bottom.equalTo(backBtn)
            maker.width.equalTo(56)
            maker.height.equalTo(44)
        }

        backgroundView.snp.makeConstraints { maker in
            maker.edges.equalTo(self)
        }

        shadowView.snp.makeConstraints { maker in
            maker.edges.equalTo(self)
        }
    }

    @discardableResult
    func with(title text: String?) -> MHHeaderView {
        self.titleLabel.text = text
        return self
    }

    func addTarget(back target: Any?, action: Selector) {
        backBtn.isHidden = false
        backBtn.addTarget(target, action: action, for: .touchUpInside)
    }

    func addTarget(more target: Any?, action: Selector) {
        moreBtn.isHidden = false
        moreBtn.addTarget(target, action: action, for: .touchUpInside)
    }

    var background: Bool = true {
        didSet {
            backgroundView.isHidden = !background
            shadowView.isHidden = !background
        }
    }

    var isTitleHidden: Bool = false {
        didSet  {
            titleLabel.isHidden = isTitleHidden
        }
    }

    var isBlack: Bool = true{
        didSet {
            if isBlack {
                self.titleLabel.textColor = .black
                self.backBtn.tintColor = .black
                self.moreBtn.tintColor = .black
            } else {
                self.titleLabel.textColor = .white
                self.backBtn.tintColor = .white
                self.moreBtn.tintColor = .white
            }
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