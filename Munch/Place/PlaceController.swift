//
//  PlaceController.swift
//  Munch
//
//  Created by Fuxing Loh on 28/3/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage
import SnapKit
import MXSegmentedPager

class PlaceViewController: MXSegmentedPagerController {
    var place: Place!
    
    let imageGradientBorder = UIView()
    @IBOutlet weak var placeHeaderView: UIView!
    @IBOutlet weak var placeImageGradientView: UIView!
    @IBOutlet weak var placeImageView: UIImageView!
    
    @IBOutlet weak var placeRatingLabel: UILabel!
    @IBOutlet weak var placeRatingBottom: NSLayoutConstraint!
    @IBOutlet weak var placeNavBar: PlaceNavBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.segmentedPager.backgroundColor = UIColor.white
        self.segmentedPager.pager.isScrollEnabled = false
        
        // Parallax Header
        self.segmentedPager.parallaxHeader.view = placeHeaderView
        self.segmentedPager.parallaxHeader.mode = .fill
        self.segmentedPager.parallaxHeader.height = 320
        self.segmentedPager.parallaxHeader.minimumHeight = 53 + 64
        
        // Add gradient bar for image so that nav bar buttons and status bar can be seen
        let placeImageGradient = CAGradientLayer()
        placeImageGradient.frame = CGRect(x: 0, y: 0, width: UIScreen.width, height: 64)
        placeImageGradient.colors = [UIColor.black.withAlphaComponent(0.8).cgColor, UIColor.clear.cgColor]
        placeImageView.layer.insertSublayer(placeImageGradient, at: 0)
        
        // Add border line for placeImageGradientView
        imageGradientBorder.isHidden = true
        imageGradientBorder.backgroundColor = UIBorder.color
        placeImageGradientView.addSubview(imageGradientBorder)
        imageGradientBorder.snp.makeConstraints { make in
            make.height.equalTo(UIBorder.onePixel)
            make.left.equalTo(placeImageGradientView)
            make.right.equalTo(placeImageGradientView)
            make.bottom.equalTo(placeImageGradientView)
        }
        
        // Segmented Control customization
        let control = self.segmentedPager.segmentedControl
        control.selectionIndicatorLocation = .none
        control.segmentWidthStyle = .fixed
        control.backgroundColor = UIColor.white
        control.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: UIFont.systemFont(ofSize: 16, weight: UIFontWeightLight)
        ]
        control.selectedTitleTextAttributes = [
            NSForegroundColorAttributeName: UIColor(hex: "458eff")
        ]
        
        // Create border for segmented control top and bottom
        let topBorder = UIView()
        topBorder.backgroundColor = UIBorder.color
        control.addSubview(topBorder)
        topBorder.snp.makeConstraints { make in
            make.height.equalTo(UIBorder.onePixel)
            make.left.equalTo(control)
            make.right.equalTo(control)
            make.top.equalTo(control)
        }
        let bottomBorder = UIView()
        bottomBorder.backgroundColor = UIBorder.color
        control.addSubview(bottomBorder)
        bottomBorder.snp.makeConstraints { make in
            make.height.equalTo(UIBorder.onePixel)
            make.left.equalTo(control)
            make.right.equalTo(control)
            make.bottom.equalTo(control)
        }
        
        // Create rating view to be placed on top of navigation bar
        placeRatingLabel.layer.cornerRadius = 4
        placeRatingLabel.layer.borderWidth = 1.0
        placeRatingLabel.layer.masksToBounds = true
        
        // Finally render the place data
        render(place: place)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        // Style the navbar with didScrollWith method, which is based on existing parallaxHeader
        segmentedPager(segmentedPager, didScrollWith: self.segmentedPager.parallaxHeader)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.barStyle = .default
    }
    
    override func segmentedPager(_ segmentedPager: MXSegmentedPager, titleForSectionAt index: Int) -> String {
        return ["General", "Gallery", "Articles", "Reviews"][index]
    }
    
    /**
     Update gradient of image nav bar, progress 1.0 means full image
     Progress 0 means image hidden
     */
    override func segmentedPager(_ segmentedPager: MXSegmentedPager, didScrollWith parallaxHeader: MXParallaxHeader) {
        let colorProgress = 1.0 - parallaxHeader.progress/0.7
        if (colorProgress < 0.5){
            // Transiting to white
            placeImageGradientView.backgroundColor = UIColor.white.withAlphaComponent(colorProgress*2)
            navigationController?.navigationBar.barStyle = .blackTranslucent
            navigationController?.navigationBar.tintColor = UIColor.white
            imageGradientBorder.isHidden = true
            
            // Name label progress
            self.navigationItem.title = nil
            self.placeNavBar.placeNameLabel.textColor = UIColor.black
        } else {
            // Fullly white bar
            placeImageGradientView.backgroundColor = UIColor.white
            navigationController?.navigationBar.barStyle = .default
            navigationController?.navigationBar.tintColor = UIColor.black
            imageGradientBorder.isHidden = false
            
            // Name label progress for secondary nav bar
            let nameProgress = 0.65/colorProgress - 0.65
            self.navigationItem.title = place.name
            self.placeNavBar.placeNameLabel.textColor = UIColor.black.withAlphaComponent(nameProgress)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? PlaceControllers {
            controller.place = place
        }
    }
    
    /**
     Render place struct to place controller
     */
    func render(place: Place) {
        // Render image view
        if let imageURL = place.imageURL() {
            self.placeImageView.sd_setImage(with: imageURL)
        }
        // Render rating label
        let ratingColor = UIColor(hex: "5CB85C")
        placeRatingLabel.text = "4.9"
        placeRatingLabel.backgroundColor = ratingColor
        placeRatingLabel.layer.borderColor = ratingColor.cgColor
        
        // Render sticky bar
        self.placeNavBar.render(place: place)
    }
    
}

/**
 Place nav bar that appear under the parallex image
 */
class PlaceNavBar: UIView {
    
    @IBOutlet weak var placeMainButton: UIButton!
    @IBOutlet weak var placeNameLabel: UILabel!
    
    func render(place: Place) {
        placeNameLabel.text = place.name
        
        placeMainButton.backgroundColor = .clear
        placeMainButton.layer.cornerRadius = 5
        placeMainButton.layer.borderWidth = 1
        placeMainButton.layer.borderColor = UIColor(hex: "458eff").cgColor
    }
}

/**
 Abstract controllers for place segues
 */
class PlaceControllers: UIViewController {
    var place: Place!
}

/**
 Place controller for general place data
 in General Tab
 */
class PlaceGeneralController: PlaceControllers {
    
}

/**
 Place controller for gallery instagram data
 in Gallery Tab
 */
class PlaceGalleryController: PlaceControllers, UICollectionViewDataSource, UICollectionViewDelegate {
    let client = MunchClient()
    
    @IBOutlet weak var galleryCollection: UICollectionView!
    @IBOutlet weak var galleryFlowLayout: UICollectionViewFlowLayout!
    
    var graphics = [Graphic]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.galleryFlowLayout.estimatedItemSize = CGSize(width: 100, height: 100)
        self.galleryCollection.dataSource = self
        self.galleryCollection.delegate = self
        
        client.places.gallery(id: place.id!){ meta, graphics in
            if (meta.isOk()){
                self.graphics += graphics
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
        return graphics.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if (indexPath.row == 0){
            return collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceGalleryHeaderCell", for: indexPath) as! PlaceGalleryHeaderCell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceGalleryContentCell", for: indexPath) as! PlaceGalleryContentCell
        cell.render(graphic: graphics[indexPath.row - 1])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
}

/**
 Gallery header cell for title
 */
class PlaceGalleryHeaderCell: UICollectionViewCell {
    @IBOutlet weak var headerLabel: UILabel!
    var isHeightCalculated: Bool = false

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        if !isHeightCalculated {
            layoutAttributes.frame.size.width = UIScreen.width - 24
            layoutAttributes.frame.size.height = 40
            isHeightCalculated = true
        }
        return layoutAttributes
    }
}

/**
 Gallery content cell for instagram images
 */
class PlaceGalleryContentCell: UICollectionViewCell {
    @IBOutlet weak var galleryImageView: UIImageView!
    var isHeightCalculated: Bool = false
    
    func render(graphic: Graphic) {
        galleryImageView.sd_setImage(with: graphic.imageURL())
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        if !isHeightCalculated {
            let workingWidth = UIScreen.width - 34
            let halfWidth = CGFloat(floorf(Float(workingWidth/2.0)))
            layoutAttributes.frame.size.width = halfWidth
            layoutAttributes.frame.size.height = halfWidth
            isHeightCalculated = true
        }
        return layoutAttributes
    }
}







