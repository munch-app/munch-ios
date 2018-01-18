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

        self.collectionView.delegate = self
        self.collectionView.dataSource = self
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

    private var squareWidth: CGFloat {
        return (UIScreen.main.bounds.width - 24 * 3) / 2
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 1 {
            return CGSize(width: UIScreen.main.bounds.width - 24 * 2, height: self.squareWidth)
        }

        return CGSize(width: self.squareWidth, height: self.squareWidth)
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
//        if let loader = self.dataLoader, loader.more {
//            loader.append(load: { meta in
//                DispatchQueue.main.async {
//                    guard self.headerView.selectedItem == loader.selectedData else {
//                        return // User changed tab
//                    }
//
//                    if (meta.isOk()) {
//                        if (loader.more) {
//                            self.collectionView.reloadData()
//                        } else {
//                            if (loader.isEmpty) {
//                                self.collectionView.reloadData()
//                            }
//                            let cell = self.collectionView.cellForItem(at: .init(row: 0, section: 1)) as? PlaceDataLoadingCardCell
//                            cell?.stopAnimating()
//                        }
//                    } else {
//                        self.present(meta.createAlert(), animated: true)
//                    }
//                }
//            })
//        }
    }
}

fileprivate class AccountDataLikedPlaceCell: UICollectionViewCell {
    private let imageView: ShimmerImageView = {
        let view = ShimmerImageView()
        view.layer.cornerRadius = 2
        view.backgroundColor = UIColor(hex: "F0F0F0")
        return view
    }()

    // TODO Name & More?

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    func render(likedPlace: LikedPlace) {
        imageView.render(sourcedImage: likedPlace.place.images?.get(0))
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

fileprivate enum UserAccountDataType {
    case like(LikedPlace)
    case collection(PlaceCollection)
}

class UserAccountDataLoader {
    var likes: [LikedPlace] = []
    var collections: [PlaceCollection] = []

    var selectedType = "LIKES" // ["LIKES", "COLLECTIONS"]

    fileprivate var items: [UserAccountDataType] {
        switch selectedType {
        case "LIKES":
            return likes.map({ UserAccountDataType.like($0) })
        case "COLLECTIONS":
            return collections.map({ UserAccountDataType.collection($0) })
        default: return []
        }
    }

    // TODO Loaders
}