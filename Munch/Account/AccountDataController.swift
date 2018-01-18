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
        self.collectionView.register(AccountDataEmptyCollectionCell.self, forCellWithReuseIdentifier: "AccountDataEmptyCollectionCell")

        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        self.collectionView.contentInset.top = self.headerView.contentHeight
        self.collectionView.contentInsetAdjustmentBehavior = .always
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return dataLoader.items.count
        case 1: return 1 // Loader & Space Filler Cell
        default: return 0
        }
    }

    private var squareWidth: CGFloat {
        return (UIScreen.main.bounds.width - 24 * 3) / 2
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 1 {
            return CGSize(width: UIScreen.main.bounds.width - 24 * 2, height: self.squareWidth)
        }

        switch dataLoader.items[indexPath.row] {
        case .like:
            fallthrough
        case .collection:
            return CGSize(width: self.squareWidth, height: self.squareWidth)
        case .emptyLike:
            fallthrough
        case .emptyCollection:
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
            cell.render(place: placeCollection)
            return cell
        case .emptyLike:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "AccountDataEmptyLikeCell", for: indexPath)
        case .emptyCollection:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "AccountDataEmptyCollectionCell", for: indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            return
        }

        switch dataLoader.items[indexPath.row] {
        case .like(let likedPlace):
            if let placeId = likedPlace.place.id {
                let controller = PlaceViewController(placeId: placeId)
                self.navigationController!.pushViewController(controller, animated: true)
            }
        case .collection:
            // TODO Next Version
            return
        default:
            return
        }
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
        if dataLoader.more {
            dataLoader.append(delegate: self, load: { meta in
                DispatchQueue.main.async {
                    guard self.headerView.selectedType == self.dataLoader.selectedType else {
                        return // User changed tab
                    }

                    if (meta.isOk()) {
                        if (self.dataLoader.more) {
                            self.collectionView.reloadData()
                        } else {
                            if (self.dataLoader.isEmpty) {
                                self.collectionView.reloadData()
                            }
                            let cell = self.collectionView.cellForItem(at: .init(row: 0, section: 1)) as? AccountDataLoadingCell
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
        layer.frame = CGRect(x: 0, y: 0, width: 50, height: 30)
        layer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.55).cgColor]
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
            make.left.right.equalTo(self).inset(8)
            make.bottom.equalTo(self).inset(8)
        }
    }

    func render(likedPlace: LikedPlace) {
        imageView.render(sourcedImage: likedPlace.place.images?.get(0))
        nameLabel.text = likedPlace.place.name
    }

    override func layoutSubviews() {
        super.layoutSubviews()
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
        view.backgroundColor = UIColor(hex: "F0F0F0")
        return view
    }()

    // TODO Name, Next Version

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    func render(place: PlaceCollection) {
        imageView.render(images: place.thumbnail)
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

fileprivate class AccountDataEmptyCollectionCell: UICollectionViewCell {
    private let label: UILabel = {
        let label = UILabel()
        label.text = "You haven create any collections."
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

fileprivate class AccountDataEmptyLikeCell: UICollectionViewCell {
    private let label: UILabel = {
        let label = UILabel()
        label.text = "You haven liked any places."
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
    case emptyCollection
}

class UserAccountDataLoader {
    var likes: [[LikedPlace]] = []
    var collections: [[PlaceCollection]] = []

    var selectedType = "LIKES" // ["LIKES", "COLLECTIONS"]

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
                let items = collections.joined().map({ UserAccountDataType.collection($0) })
                if items.isEmpty {
                    return [UserAccountDataType.emptyCollection]
                }
                return items
            }
        default: return []
        }
    }

    var isEmpty: Bool {
        switch selectedType {
        case "LIKES":
            return likes.joined().isEmpty
        case "LIKES":
            return collections.joined().isEmpty
        default: return false
        }
    }

    var more: Bool {
        switch selectedType {
        case "LIKES":
            return !(likes.last?.isEmpty ?? false)
        case "COLLECTIONS":
            return !(collections.last?.isEmpty ?? false)
        default: return false
        }
    }

    private func join<T>(_ dataList: [[T]], _ transform: (T) -> UserAccountDataType) -> [UserAccountDataType] {
        if dataList.isEmpty {
            return []
        } else {
            if dataList.joined().isEmpty {
                // No data found
                return []
            } else {
                return dataList.joined().map(transform)
            }
        }
    }

    func select(type: String) {
        self.selectedType = type
    }

    func append(delegate: UIViewController, load completion: @escaping (_ meta: MetaJSON) -> Void) {
        switch selectedType {
        case "LIKES":
            MunchApi.collections.liked.list(maxSortKey: likes.last?.last?.sortKey, size: 10) { meta, likes in
                if meta.isOk() {
                    self.likes.append(likes)
                } else {
                    delegate.present(meta.createAlert(), animated: true)
                }
                completion(meta)
            }
        case "COLLECTIONS":
            MunchApi.collections.list(maxSortKey: collections.last?.last?.sortKey, size: 10) { meta, collections in
                if meta.isOk() {
                    self.collections.append(collections)
                } else {
                    delegate.present(meta.createAlert(), animated: true)
                }
                completion(meta)
            }
        default: break
        }
    }
}