//
//  GalleryController.swift
//  Munch
//
//  Created by Fuxing Loh on 9/4/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import Kingfisher
import UIKit

/**
 Place controller for gallery instagram data
 in Gallery Tab
 */
class PlaceGalleryController: PlaceControllers, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    let client = MunchClient()
    
    @IBOutlet weak var galleryCollection: UICollectionView!
    @IBOutlet weak var galleryFlowLayout: UICollectionViewFlowLayout!
    let minSpacing: CGFloat = 20
    var contentSize: CGSize!
    
    var medias = [Media]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.galleryCollection.dataSource = self
        self.galleryCollection.delegate = self
        
        // Calculating insets, content size and spacing size for flow layout
        let width = galleryCollection.frame.width
        let halfWidth = Float(width - minSpacing * 3)/2.0
        self.contentSize = CGSize(width: CGFloat(floorf(halfWidth)), height: CGFloat(floorf(halfWidth)))
        
        // Apply sizes to flow layout
        self.galleryFlowLayout.sectionInset = UIEdgeInsets(top: 18, left: minSpacing, bottom: 16, right: minSpacing)
        self.galleryFlowLayout.minimumLineSpacing = minSpacing
        self.galleryFlowLayout.minimumInteritemSpacing = floorf(halfWidth) == halfWidth ? minSpacing : minSpacing + 1
        
        client.places.gallery(id: place.id!){ meta, medias in
            if (meta.isOk()){
                self.medias += medias
                self.galleryCollection.reloadData()
            }else{
                self.present(meta.createAlert(), animated: true, completion: nil)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.galleryCollection.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return medias.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if (indexPath.row == 0){
            return collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceGalleryHeaderCell", for: indexPath) as! PlaceGalleryHeaderCell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceGalleryContentCell", for: indexPath) as! PlaceGalleryContentCell
        cell.render(media: medias[indexPath.row - 1])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if (indexPath.row == 0) {
            return CGSize(width: UIScreen.width - minSpacing * 2, height: 26)
        }
        return contentSize
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (indexPath.row != 0) {
            if (UIApplication.shared.canOpenURL(URL(string:"instagram://")!)) {
                UIApplication.shared.open(URL(string:"instagram://media?id=" + "1444902121135780549_67451")!)
            } else {
                // TODO: SFSafariWebController if no instagram installed
            }
        }
    }
    
}

/**
 Gallery header cell for title
 */
class PlaceGalleryHeaderCell: UICollectionViewCell {
    @IBOutlet weak var headerLabel: UILabel!
}

/**
 Gallery content cell for instagram images
 */
class PlaceGalleryContentCell: UICollectionViewCell {
    @IBOutlet weak var galleryImageView: UIImageView!
    
    func render(media: Media) {
        galleryImageView.kf.setImage(with: media.imageURL())
    }
}




