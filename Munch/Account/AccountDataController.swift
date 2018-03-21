//
// Created by Fuxing Loh on 18/1/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import NVActivityIndicatorView

extension AccountProfileController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func initAccountData() {
        self.collectionView.register(AccountDataLikedPlaceCell.self, forCellWithReuseIdentifier: "AccountDataLikedPlaceCell")
        self.collectionView.register(AccountDataCollectionCell.self, forCellWithReuseIdentifier: "AccountDataCollectionCell")
        self.collectionView.register(AccountDataLoadingCell.self, forCellWithReuseIdentifier: "AccountDataLoadingCell")
        self.collectionView.register(AccountDataEmptyLikeCell.self, forCellWithReuseIdentifier: "AccountDataEmptyLikeCell")
        self.collectionView.register(AccountDataCollectionCreateCell.self, forCellWithReuseIdentifier: "AccountDataCollectionCreateCell")

        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        self.collectionView.contentInset.top = self.headerView.contentHeight // Top Override
        self.collectionView.contentInsetAdjustmentBehavior = .always

        // Initial Refresh Control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(collectionView(handleRefresh:)), for: .valueChanged)
        refreshControl.tintColor = UIColor.black.withAlphaComponent(0.7)
        self.collectionView.addSubview(refreshControl)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return dataLoader.items.count
        case 1: return 1 // Loader & Space Filler Cell
        default: return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if (section == 0) {
            return UIEdgeInsets(top: 18, left: 24, bottom: 18, right: 24)
        }
        return .zero
    }

    private var squareWidth: CGFloat {
        return (UIScreen.main.bounds.width - 24 * 3) / 2
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 1 {
            return CGSize(width: UIScreen.main.bounds.width - 24 * 2, height: 40)
        }

        switch dataLoader.items[indexPath.row] {
        case .like:
            fallthrough
        case .collection:
            fallthrough
        case .createCollection:
            return CGSize(width: self.squareWidth, height: self.squareWidth)
        case .emptyLike:
            return CGSize(width: UIScreen.main.bounds.width - 24 * 2, height: self.squareWidth)
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 1 {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "AccountDataLoadingCell", for: indexPath)
        }

        switch dataLoader.items[indexPath.row] {
        case .like(let likedPlace):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AccountDataLikedPlaceCell", for: indexPath) as! AccountDataLikedPlaceCell
            cell.render(likedPlace: likedPlace)
            return cell
        case .collection(let placeCollection):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AccountDataCollectionCell", for: indexPath) as! AccountDataCollectionCell
            cell.render(collection: placeCollection)
            return cell
        case .emptyLike:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "AccountDataEmptyLikeCell", for: indexPath)
        case .createCollection:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "AccountDataCollectionCreateCell", for: indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            return
        }

        switch dataLoader.items[indexPath.row] {
        case .createCollection:
            let alert = UIAlertController(title: "Create New Collection", message: "Enter a name for this new collection", preferredStyle: .alert)
            alert.addTextField { textField in
                textField.text = nil
            }
            alert.addAction(.init(title: "CANCEL", style: .destructive))
            alert.addAction(.init(title: "OK", style: .default) { action in
                let textField = alert.textFields![0]
                var collection = PlaceCollection()
                collection.name = textField.text

                MunchApi.collections.post(collection: collection) { meta, collection in
                    if meta.isOk(), let collection = collection {
                        self.dataLoader.collections.insert([collection], at: 0)
                        self.collectionView.reloadData()
                    } else {
                        self.present(meta.createAlert(), animated: true)
                    }
                }
            })
            self.present(alert, animated: true, completion: nil)
        case .like(let likedPlace):
            if let placeId = likedPlace.place.id {
                let controller = PlaceViewController(placeId: placeId)
                self.navigationController!.pushViewController(controller, animated: true)
            }
        case .collection(let placeCollection):
            if let collectionId = placeCollection.collectionId {
                let controller = CollectionPlaceController(collectionId: collectionId, placeCollection: placeCollection)
                self.navigationController?.pushViewController(controller, animated: true)
            }
        default:
            return
        }
    }

    @objc func collectionView(handleRefresh refreshControl: UIRefreshControl) {
        dataLoader.reset()
        collectionView.reloadData()
        refreshControl.endRefreshing()
    }
}

// Lazy Append Loading
extension AccountProfileController {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        switch indexPath {
        case [1, 0]:
            self.appendLoad()
        default: break
        }
    }

    private func appendLoad() {
        if dataLoader.more, !dataLoader.isLoading {
            let loadingCell = self.collectionView.cellForItem(at: .init(row: 0, section: 1)) as? AccountDataLoadingCell
            loadingCell?.startAnimating()

            dataLoader.append(delegate: self, load: { meta in
                DispatchQueue.main.async {
                    guard self.headerView.selectedType == self.dataLoader.selectedType else {
                        return // User changed tab
                    }

                    if (meta.isOk()) {
                        if (!self.dataLoader.more) {
                            let loadingCell = self.collectionView.cellForItem(at: .init(row: 0, section: 1)) as? AccountDataLoadingCell
                            loadingCell?.stopAnimating()
                        }
                        self.collectionView.reloadData()
                    } else {
                        self.present(meta.createAlert(), animated: true)
                    }
                }
            })
        } else {
            let loadingCell = self.collectionView.cellForItem(at: .init(row: 0, section: 1)) as? AccountDataLoadingCell
            loadingCell?.stopAnimating()
        }
    }
}

// MARK: Scroll View
extension AccountProfileController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.headerView.contentDidScroll(scrollView: scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (!decelerate) {
            scrollViewDidFinish(scrollView)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidFinish(scrollView)
    }

    func scrollViewDidFinish(_ scrollView: UIScrollView) {
        // Check nearest locate and move to it
        if let y = self.headerView.contentShouldMove(scrollView: scrollView) {
            let point = CGPoint(x: 0, y: y)
            scrollView.setContentOffset(point, animated: true)
        }
    }
}

fileprivate class AccountDataLikedPlaceCell: UICollectionViewCell {
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        return layer
    }()

    private let imageGradientView: UIView = {
        let imageGradientView = UIView()
        imageGradientView.layer.cornerRadius = 2
        imageGradientView.backgroundColor = .clear
        return imageGradientView
    }()
    private let imageView: ShimmerImageView = {
        let view = ShimmerImageView()
        view.layer.cornerRadius = 2
        view.backgroundColor = UIColor(hex: "F0F0F0")
        return view
    }()
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 13.0, weight: .medium)
        return label
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)
        self.addSubview(imageGradientView)
        self.addSubview(nameLabel)

        imageGradientView.layer.insertSublayer(gradientLayer, at: 0)
        imageGradientView.snp.makeConstraints { make in
            make.bottom.equalTo(self)
            make.left.right.equalTo(self)
            make.height.equalTo(30)
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        nameLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(11)
            make.bottom.equalTo(self).inset(8)
        }
    }

    func render(likedPlace: LikedPlace) {
        imageView.render(sourcedImage: likedPlace.place.images?.get(0))
        nameLabel.text = likedPlace.place.name
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.55).cgColor]
        self.gradientLayer.cornerRadius = 2
        self.gradientLayer.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: 30)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class AccountDataCollectionCell: UICollectionViewCell {
    private let imageView: ShimmerImageView = {
        let view = ShimmerImageView()
        view.layer.cornerRadius = 2
        view.backgroundColor = UIColor(hex: "AAAAAA")
        return view
    }()
    private let imageGradientView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        return view
    }()
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
        return label
    }()
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
        return label
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)
        self.addSubview(imageGradientView)
        self.addSubview(nameLabel)
        self.addSubview(descriptionLabel)

        imageView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        imageGradientView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(self).inset(8)
            make.left.right.equalTo(self).inset(11)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.bottom.equalTo(self).inset(8)
            make.left.right.equalTo(self).inset(11)
        }
    }

    func render(collection: PlaceCollection) {
        nameLabel.text = collection.name
        descriptionLabel.text = "\(collection.count ?? 0) Places"
        imageView.render(images: collection.thumbnail)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class AccountDataLoadingCell: UICollectionViewCell {
    private var indicator: NVActivityIndicatorView!

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: UIScreen.main.bounds.width, height: 40))
        self.indicator = NVActivityIndicatorView(frame: frame, type: .ballBeat, color: .primary700, padding: 0)
        indicator.startAnimating()
        self.addSubview(indicator)

        indicator.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.height.equalTo(40)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimating() {
        self.indicator.startAnimating()
    }

    func stopAnimating() {
        self.indicator.stopAnimating()
    }
}

fileprivate class AccountDataCollectionCreateCell: UICollectionViewCell {
    private let imageView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.backgroundColor = UIColor(hex: "AAAAAA")
        return view
    }()
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Make A New Collection"
        label.numberOfLines = 0
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
        return label
    }()
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Collect and share places in Munch"
        label.numberOfLines = 0
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
        return label
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)
        self.addSubview(nameLabel)
        self.addSubview(descriptionLabel)

        imageView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(self).inset(8)
            make.left.right.equalTo(self).inset(11)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.bottom.equalTo(self).inset(8)
            make.left.right.equalTo(self).inset(11)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class AccountDataEmptyLikeCell: UICollectionViewCell {
    private let label: UILabel = {
        let label = UILabel()
        label.text = "Hit like to save your favourite spots here"
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

fileprivate enum UserAccountDataType {
    case like(LikedPlace)
    case collection(PlaceCollection)
    case emptyLike
    case createCollection
}

class UserAccountDataLoader {
    private let defaultSize = 10
    var likes: [[LikedPlace]] = []
    var collections: [[PlaceCollection]] = []
    var loading = false

    var selectedType = "LIKES" // ["LIKES", "COLLECTIONS"]

    func select(type: String) {
        self.selectedType = type
    }

    fileprivate var items: [UserAccountDataType] {
        switch selectedType {
        case "LIKES":
            if likes.isEmpty {
                return []
            } else {
                let items = likes.joined().map({ UserAccountDataType.like($0) })
                if items.isEmpty {
                    return [UserAccountDataType.emptyLike]
                }
                return items
            }
        case "COLLECTIONS":
            if collections.isEmpty {
                return []
            } else {
                return [UserAccountDataType.createCollection] + collections.joined().map({ UserAccountDataType.collection($0) })
            }
        default: return []
        }
    }

    private var currentList: [[Any]] {
        switch selectedType {
        case "LIKES":
            return likes
        case "COLLECTIONS":
            return collections
        default: return []
        }
    }

    var isEmpty: Bool {
        return currentList.joined().isEmpty
    }

    var more: Bool {
        if let last = currentList.last {
            // If last count is same as default size means more to load
            return last.count == defaultSize
        }
        // No last means haven loaded anything
        return true
    }

    func reset() {
        switch selectedType {
        case "LIKES":
            likes = []
        case "COLLECTIONS":
            collections = []
        default:
            return
        }
    }

    func resetAll() {
        self.likes = []
        self.collections = []
    }

    var isLoading: Bool {
        return loading
    }

    func append(delegate: UIViewController, load completion: @escaping (_ meta: MetaJSON) -> Void) {
        self.loading = true

        switch selectedType {
        case "LIKES":
            MunchApi.collections.liked.list(maxSortKey: likes.last?.last?.sortKey, size: defaultSize) { meta, likes in
                if meta.isOk() {
                    self.likes.append(likes)
                } else {
                    delegate.present(meta.createAlert(), animated: true)
                }
                self.loading = false
                completion(meta)
            }
        case "COLLECTIONS":
            MunchApi.collections.list(maxSortKey: collections.last?.last?.sortKey, size: defaultSize) { meta, collections in
                if meta.isOk() {
                    self.collections.append(collections)
                } else {
                    delegate.present(meta.createAlert(), animated: true)
                }
                self.loading = false
                completion(meta)
            }
        default: break
        }
    }
}