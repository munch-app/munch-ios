//
// Created by Fuxing Loh on 16/4/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit

fileprivate struct OnboardingData {
    var image: UIImage?
    var color: UIColor

    var title: String
    var description: String
    var subtitle: String?
}

class OnboardingController: UIViewController {
    fileprivate let dataList: [OnboardingData] = [
        OnboardingData(image: UIImage(named: "Onboarding-Munch"), color: UIColor(hex: "fcab5a"), title: "Welcome to Munch",
                description: "Whether you're looking for the perfect date spot or the hottest bar in town - Munch helps you answer the question:",
                subtitle: "'What do you want to eat?'"),
        OnboardingData(image: UIImage(named: "Onboarding-Discover"), color: UIColor(hex: "46b892"), title: "Discover Delicious",
                description: "Explore thousands of restaurants, bars and hawkers in the app. Find places nearby or on the other end of the island.",
                subtitle: nil),
        OnboardingData(image: UIImage(named: "Onboarding-Collection"), color: UIColor(hex: "258edd"), title: "Save Your Spots",
                description: "Save places that you want to check out or create themed lists to keep track of places.",
                subtitle: nil),
    ]

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = UIColor.white
        collectionView.register(OnboardingCell.self, forCellWithReuseIdentifier: "OnboardingCell")
        return collectionView
    }()
    private let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.pageIndicatorTintColor = UIColor(hex: "D0D0D0")
        control.currentPageIndicatorTintColor = UIColor(hex: "A0A0A0")
        return control
    }()
    private let cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("SKIP", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.titleEdgeInsets.right = 24
        button.contentHorizontalAlignment = .right
        return button
    }()
    private let continueButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 3
        button.backgroundColor = .primary
        button.setTitle("Continue", for: .normal)
        button.contentEdgeInsets.left = 40
        button.contentEdgeInsets.right = 40
        button.setTitleColor(.white, for: .normal)
        button.titleLabel!.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        return button
    }()

    class var isShown: Bool {
        get {
//            return false
            return UserDefaults.standard.string(forKey: "onboarding.app.load.version") == "1"
        }
        set(value) {
            UserDefaults.standard.set(value ? "1" : nil, forKey: "onboarding.app.load.version")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        OnboardingController.isShown = true
        self.view.addSubview(collectionView)
        self.view.addSubview(cancelButton)
        self.view.addSubview(pageControl)
        self.view.addSubview(continueButton)
        self.pageControl.numberOfPages = self.dataList.count

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeArea.top)
            make.height.equalTo(44)
            make.width.equalTo(90)
            make.right.equalTo(self.view)
        }

        pageControl.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.view.safeArea.bottom).inset(30)
        }

        continueButton.isHidden = true
        continueButton.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(self.view.safeArea.bottom).inset(30)
        }

        cancelButton.addTarget(self, action: #selector(onCancel(_:)), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(onCancel(_:)), for: .touchUpInside)
    }

    @objc func onCancel(_ sender: Any) {
        self.dismiss(animated: true)
    }
}

extension OnboardingController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let data = dataList[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OnboardingCell", for: indexPath) as! OnboardingCell
        cell.render(data: data)
        return cell
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = Int(round(scrollView.contentOffset.x / scrollView.frame.size.width))
        pageControl.currentPage = pageNumber

        if pageNumber == dataList.count - 1 {
            pageControl.isHidden = true
            continueButton.isHidden = false
        }
    }
}

fileprivate class OnboardingCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private let containerView: UIView = {
        let view = UIView()
        return view
    }()
    private let titleView: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0

        label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        return label
    }()
    private let descriptionView: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0

        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        return label
    }()
    private let subtitleView: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0

        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(containerView)
        containerView.addSubview(imageView)
        self.addSubview(titleView)
        self.addSubview(descriptionView)
        self.addSubview(subtitleView)
        self.backgroundColor = .white

        containerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self)
            make.height.equalTo(self).dividedBy(1.85)
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalTo(containerView).inset(50)
        }

        titleView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.equalTo(containerView.snp.bottom).inset(-30)
        }

        descriptionView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.equalTo(titleView.snp.bottom).inset(-30)
        }

        subtitleView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.equalTo(descriptionView.snp.bottom).inset(-20)
        }
    }

    func render(data: OnboardingData) {
        self.containerView.backgroundColor = data.color
        self.imageView.image = data.image
        self.titleView.text = data.title
        self.descriptionView.text = data.description
        self.subtitleView.text = data.subtitle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}