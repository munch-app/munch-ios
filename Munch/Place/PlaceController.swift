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
    @IBOutlet weak var placeNavBar: PlaceNavBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.segmentedPager.backgroundColor = UIColor.white
        self.segmentedPager.pager.isScrollEnabled = true // Scrolling of page from side to side
        
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
        
        // Add shadow/border line for placeImageGradientView
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
            NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.85),
            NSFontAttributeName: UIFont.systemFont(ofSize: 16, weight: UIFontWeightLight)
        ]
        control.selectedTitleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium)
        ]
        
        // Create border for segmented control top and bottom
        let topBorder = UIView()
        let bottomBorder = UIView()
        control.addSubview(topBorder)
        control.addSubview(bottomBorder)
        topBorder.backgroundColor = UIBorder.color
        bottomBorder.backgroundColor = UIBorder.color
        // Add constraint for top/bottom border
        topBorder.snp.makeConstraints { make in
            make.height.equalTo(UIBorder.onePixel)
            make.left.equalTo(control)
            make.right.equalTo(control)
            make.top.equalTo(control)
        }
        bottomBorder.snp.makeConstraints{ make in
            make.height.equalTo(UIBorder.onePixel)
            make.left.equalTo(control)
            make.right.equalTo(control)
            make.bottom.equalTo(control)
        }
        
        // Selected; top segment control
        segmentedPager.segmentedControl.indexChangeBlock = { index in
            self.segmentedPager(self.segmentedPager, didSelectViewWith: index)
        }
        
        // Finally render the place data
        render(place: place)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func segmentedPager(_ segmentedPager: MXSegmentedPager, titleForSectionAt index: Int) -> String {
        return ["General", "Gallery", "Articles", "Reviews"][index]
    }
    
    /**
     Animate; hide/show parallaxHeader based on selected index
     */
    override func segmentedPager(_ segmentedPager: MXSegmentedPager, didSelectViewWith index: Int) {
        if (index == 0) {
            self.segmentedPager.bounces = true
            self.segmentedPager.contentView.isScrollEnabled = true
        }else{
            self.segmentedPager.bounces = false
            self.segmentedPager.contentView.isScrollEnabled = false
            self.segmentedPager.contentView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        }
    }
    
    /**
     Update gradient of image nav bar, progress 1.0 means full image
     Progress 0 means image hidden
     */
    override func segmentedPager(_ segmentedPager: MXSegmentedPager, didScrollWith parallaxHeader: MXParallaxHeader) {
        let progress = 1.0 - parallaxHeader.progress/0.8
        if (progress < 0.5) {
            // Transiting to white
            placeImageGradientView.backgroundColor = UIColor.white.withAlphaComponent(progress*2)
            navigationController?.navigationBar.barStyle = .blackTranslucent
            navigationController?.navigationBar.tintColor = UIColor.white
            imageGradientBorder.isHidden = true // 1px Shadow
            
            // Name label progress
            self.navigationItem.title = nil
            self.placeNavBar.placeNameLabel.textColor = UIColor.black
        } else {
            // Fullly white bar
            placeImageGradientView.backgroundColor = UIColor.white
            navigationController?.navigationBar.barStyle = .default
            navigationController?.navigationBar.tintColor = UIColor.black
            imageGradientBorder.isHidden = false // 1px Shadow
            
            // Name label progress for secondary nav bar
            self.navigationItem.title = place.name
            let nameProgress = 0.65/progress - 0.65
            self.placeNavBar.placeNameLabel.textColor = UIColor.black.withAlphaComponent(nameProgress)
        }
    }
    
    /**
     Pass place data to Abstract place controller
     */
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
