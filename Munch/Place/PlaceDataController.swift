//
// Created by Fuxing Loh on 8/1/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

import SnapKit
import SwiftRichString
import NVActivityIndicatorView

class PlaceDataViewController: UIViewController, UIGestureRecognizerDelegate {
    let placeId: String
    let place: Place

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 18

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = UIColor.white
        collectionView.contentInset = UIEdgeInsets(top: 18, left: 24, bottom: 18, right: 24)
        collectionView.register(PlaceDataInstagramCardCell.self, forCellWithReuseIdentifier: "PlaceDataInstagramCardCell")
        collectionView.register(PlaceDataArticleCardCell.self, forCellWithReuseIdentifier: "PlaceDataArticleCardCell")
        collectionView.register(PlaceDataLoadingCardCell.self, forCellWithReuseIdentifier: "PlaceDataLoadingCardCell") // TODO Reduce height of this card
        collectionView.register(PlaceDataEmptyCardCell.self, forCellWithReuseIdentifier: "PlaceDataEmptyCardCell")
        return collectionView
    }()
    private let headerView = PlaceDataHeaderView()
    private var dataLoader: PlaceDataLoader!

    init(place: Place, selected: String = "INSTAGRAM") {
        self.placeId = place.id!
        self.place = place
        super.init(nibName: nil, bundle: nil)
        self.headerView.selectedItem = selected
        self.headerView.delegate = self

        self.dataLoader = PlaceDataLoader(delegate: self, selectedData: selected)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        self.headerView.backButton.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)
    }

    private func initViews() {
        self.view.addSubview(collectionView)
        self.view.addSubview(headerView)

        collectionView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.equalTo(self.view)
        }

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }
    }

    func select(data: String) {
        self.dataLoader.select(data: data)
        self.collectionView.reloadData()
    }

    @objc func onBackButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class PlaceDataHeaderView: UIView {
    fileprivate var delegate: PlaceDataViewController!
    fileprivate let backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "NavigationBar-Back"), for: .normal)
        button.tintColor = .black
        button.imageEdgeInsets.left = 18
        button.contentHorizontalAlignment = .left
        return button
    }()
    fileprivate let tabsView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = false
        collectionView.backgroundColor = UIColor.white
        collectionView.register(PlaceDataHeaderCollectionCell.self, forCellWithReuseIdentifier: "PlaceDataHeaderCollectionCell")
        return collectionView
    }()
    var selectedItem: String = "Instagram"

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.initViews()
    }

    private func initViews() {
        self.backgroundColor = .white
        self.addSubview(backButton)
        self.addSubview(tabsView)

        self.tabsView.delegate = self
        self.tabsView.dataSource = self

        backButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.bottom.equalTo(self)
            make.left.equalTo(self)

            make.width.equalTo(62)
            make.height.equalTo(44)
        }

        tabsView.snp.makeConstraints { make in
            make.bottom.equalTo(self)
            make.height.equalTo(34)

            make.left.equalTo(backButton.snp.right)
            make.right.equalTo(self).inset(64)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        hairlineShadow(height: 1.0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PlaceDataHeaderView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var items: [String] {
        return ["INSTAGRAM", "ARTICLES"]
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = UILabel.textWidth(font: PlaceDataHeaderCollectionCell.labelFont, text: items[indexPath.row])
        return CGSize(width: width + 18, height: 34)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceDataHeaderCollectionCell", for: indexPath) as! PlaceDataHeaderCollectionCell
        let item = items[indexPath.row]
        cell.render(text: item, selected: item == selectedItem)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        self.selectedItem = item
        self.delegate.select(data: item)
        collectionView.reloadData()
    }

    fileprivate class PlaceDataHeaderCollectionCell: UICollectionViewCell {
        static let labelFont = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        private let nameLabel: UILabel = {
            let nameLabel = UILabel()
            nameLabel.backgroundColor = .clear
            nameLabel.font = labelFont
            nameLabel.textColor = UIColor.black.withAlphaComponent(0.85)

            nameLabel.numberOfLines = 1
            nameLabel.isUserInteractionEnabled = false

            nameLabel.textAlignment = .left
            return nameLabel
        }()
        private let indicatorView: UIView = {
            let view = UIView()
            view.backgroundColor = .primary500
            return view
        }()

        override init(frame: CGRect = .zero) {
            super.init(frame: frame)
            self.addSubview(nameLabel)
            self.addSubview(indicatorView)

            nameLabel.snp.makeConstraints { make in
                make.left.right.equalTo(self)
                make.top.equalTo(self).inset(4)
            }

            indicatorView.snp.makeConstraints { make in
                make.left.equalTo(self)
                make.right.equalTo(self).inset(18)
                make.bottom.equalTo(self)
                make.height.equalTo(2)
            }
        }

        func render(text: String?, selected: Bool) {
            nameLabel.text = text
            indicatorView.isHidden = !selected
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

fileprivate enum PlaceDataType {
    case empty
    case article(Article)
    case instagram(InstagramMedia)
}

fileprivate class PlaceDataLoader {
    let placeId: String
    var instagram: [[InstagramMedia]] = []
    var article: [[Article]] = []

    let delegate: PlaceDataViewController
    var selectedData: String

    init(delegate: PlaceDataViewController, selectedData: String) {
        self.placeId = delegate.placeId
        self.delegate = delegate
        self.selectedData = selectedData
    }

    var items: [PlaceDataType] {
        switch selectedData {
        case "INSTAGRAM":
            return items(instagram, { PlaceDataType.instagram($0) })
        case "ARTICLES":
            return items(article, { PlaceDataType.article($0) })
        default: return []
        }
    }

    var isEmpty: Bool {
        switch selectedData {
        case "INSTAGRAM":
            return instagram.joined().isEmpty
        case "ARTICLES":
            return article.joined().isEmpty
        default: return false
        }
    }

    var more: Bool {
        switch selectedData {
        case "INSTAGRAM":
            return !(instagram.last?.isEmpty ?? false)
        case "ARTICLES":
            return !(article.last?.isEmpty ?? false)
        default: return false
        }
    }

    private func items<T>(_ dataList: [[T]], _ transform: (T) -> PlaceDataType) -> [PlaceDataType] {
        if dataList.isEmpty {
            return []
        } else {
            if dataList.joined().isEmpty {
                // No data found
                return [PlaceDataType.empty]
            } else {
                return dataList.joined().map(transform)
            }
        }
    }

    func select(data: String) {
        self.selectedData = data
    }

    func append(load completion: @escaping (_ meta: MetaJSON) -> Void) {
        switch selectedData {
        case "INSTAGRAM":
            MunchApi.places.getInstagram(id: placeId, maxSort: instagram.last?.last?.placeSort, size: 20) { meta, medias in
                if meta.isOk() {
                    self.instagram.append(medias)
                } else {
                    self.delegate.present(meta.createAlert(), animated: true)
                }
                completion(meta)
            }

        case "ARTICLES":
            MunchApi.places.getArticle(id: placeId, maxSort: article.last?.last?.placeSort, size: 20) { meta, articles in
                if meta.isOk() {
                    self.article.append(articles)
                } else {
                    self.delegate.present(meta.createAlert(), animated: true)
                }
                completion(meta)
            }
        default: break
        }
    }
}

extension PlaceDataViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SFSafariViewControllerDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return dataLoader.items.count
        case 1: return 1
        default: return 0
        }

    }

    private var width: CGFloat {
        return (UIScreen.main.bounds.width - 24 * 3) / 2
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 1 {
            return CGSize(width: (self.width * 2) + 24, height: self.width)
        }

        switch dataLoader.items[indexPath.row] {
        case .empty:
            return CGSize(width: (self.width * 2) + 24, height: self.width)
        case .instagram:
            return CGSize(width: self.width, height: self.width)
        case .article:
            return CGSize(width: self.width, height: self.width / 0.9375)
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 1 {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceDataLoadingCardCell", for: indexPath)
        }

        switch dataLoader.items[indexPath.row] {
        case .empty:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceDataEmptyCardCell", for: indexPath)
        case .article(let article):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceDataArticleCardCell", for: indexPath) as! PlaceDataArticleCardCell
            cell.render(article: article)
            return cell
        case .instagram(let instagram):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceDataInstagramCardCell", for: indexPath) as! PlaceDataInstagramCardCell
            cell.render(media: instagram)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            return
        }

        switch dataLoader.items[indexPath.row] {
        case .article(let article):
            if let articleUrl = article.url, let url = URL(string: articleUrl) {
                let safari = SFSafariViewController(url: url)
                safari.delegate = self
                self.present(safari, animated: true, completion: nil)
            }
        case .instagram(let instagram):
            if let mediaId = instagram.mediaId, let url = URL(string: "instagram://media?id=\(mediaId)") {
                if (UIApplication.shared.canOpenURL(url)) {
                    UIApplication.shared.open(url)
                }
            }
        default:
            return
        }
    }
}

// Lazy Append Loading
extension PlaceDataViewController {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        switch indexPath {
        case [1, 0]:
            self.appendLoad()
        default: break
        }
    }

    private func appendLoad() {
        if let loader = self.dataLoader, loader.more {
            loader.append(load: { meta in
                DispatchQueue.main.async {
                    guard self.headerView.selectedItem == loader.selectedData else {
                        return // User changed tab
                    }

                    if (meta.isOk()) {
                        if (loader.more) {
                            self.collectionView.reloadData()
                        } else {
                            if (loader.isEmpty) {
                                self.collectionView.reloadData()
                            }
                            let cell = self.collectionView.cellForItem(at: .init(row: 0, section: 1)) as? PlaceDataLoadingCardCell
                            cell?.stopAnimating()
                        }
                    } else {
                        self.present(meta.createAlert(), animated: true)
                    }
                }
            })
        }
    }
}


fileprivate class PlaceDataInstagramCardCell: UICollectionViewCell {
    private let imageView: ShimmerImageView = {
        let view = ShimmerImageView()
        view.layer.cornerRadius = 2
        return view
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    func render(media: InstagramMedia) {
        imageView.render(images: media.images)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class PlaceDataArticleCardCell: UICollectionViewCell {
    private let articleImageView: ShimmerImageView = {
        let imageView = ShimmerImageView()
        imageView.layer.cornerRadius = 2
        return imageView
    }()
    private let articleTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        label.textColor = UIColor.black.withAlphaComponent(0.85)
        return label
    }()
    private let articleBrandLabel: UIButton = {
        let label = UIButton()
        label.titleLabel?.font = UIFont.systemFont(ofSize: 10.0, weight: .regular)
        label.setTitleColor(.white, for: .normal)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.66)
        label.contentEdgeInsets = UIEdgeInsets(topBottom: 3, leftRight: 4)
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 7
        label.isUserInteractionEnabled = false
        return label
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(articleImageView)
        self.addSubview(articleTitleLabel)
        self.addSubview(articleBrandLabel)

        articleImageView.snp.makeConstraints { (make) in
            make.left.right.equalTo(self)
            make.top.equalTo(self)
            make.width.equalTo(articleImageView.snp.height).dividedBy(0.8).priority(999)
            make.bottom.equalTo(articleTitleLabel.snp.top).inset(-4)
        }

        articleBrandLabel.snp.makeConstraints { make in
            make.right.equalTo(articleImageView).inset(5)
            make.bottom.equalTo(articleImageView).inset(5)
        }

        articleTitleLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(self)
            make.height.equalTo(20).priority(999)
            make.bottom.equalTo(self)
        }
    }

    func render(article: Article) {
        articleImageView.render(images: article.thumbnail)
        articleTitleLabel.text = article.title
        articleBrandLabel.setTitle(article.brand, for: .normal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class PlaceDataLoadingCardCell: UICollectionViewCell {
    private var indicator: NVActivityIndicatorView!

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: UIScreen.main.bounds.width, height: 25))
        self.indicator = NVActivityIndicatorView(frame: frame, type: .ballBeat, color: .primary700, padding: 56)
        indicator.startAnimating()
        self.addSubview(indicator)

        indicator.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, controller: SearchController) {
    }

    func startAnimating() {
        self.indicator.startAnimating()
    }

    func stopAnimating() {
        self.indicator.stopAnimating()
    }
}

fileprivate class PlaceDataEmptyCardCell: UICollectionViewCell {
    private let label: UILabel = {
        let label = UILabel()
        label.text = "No Result Found"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.regular)
        return label
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(label)

        label.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.bottom.equalTo(self)
            make.height.equalTo(40).priority(999)
        }
    }

    func render(text: String) {
        label.text = text
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}