//
// Created by Fuxing Loh on 18/1/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import NVActivityIndicatorView
import FirebaseAnalytics

extension AccountProfileController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
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
}