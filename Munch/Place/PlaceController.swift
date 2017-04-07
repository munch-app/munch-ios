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
            NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.85),
            NSFontAttributeName: UIFont.systemFont(ofSize: 16, weight: UIFontWeightLight)
        ]
        control.selectedTitleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium)
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
        let colorProgress = 1.0 - parallaxHeader.progress/0.8
        if (colorProgress < 0.5){
            // Transiting to white
            placeImageGradientView.backgroundColor = UIColor.white.withAlphaComponent(colorProgress*2)
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
            let nameProgress = 0.65/colorProgress - 0.65
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
class PlaceGeneralController: PlaceControllers, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    var items = [PlaceGeneralCellItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44

        prepareCellItems(place: self.place)
    }
    
    func prepareCellItems(place: Place) {
        // Menu Cell
        if let menus = place.menus {
            if (!menus.isEmpty) {
                items.append(PlaceGeneralCellItem(type: "Menu"))
            }
        }
        
        // Establishment Icon Label Cell
        if let list = place.establishments {
            if (!list.isEmpty) {
                var item = PlaceGeneralCellItem(type: "Establishment")
                item.text = list.first
                item.icon = UIImage(named: "Restaurant-26")
                items.append(item)
            }
        }
        
        // Price Range Icon Label Cell
        if let price = place.price {
            var item = PlaceGeneralCellItem(type: "PriceRange")
            let low = Int(ceil(price.lowest!))
            let high = Int(ceil(price.highest!))
            item.text = "$\(low) - $\(high)"
            item.icon = UIImage(named: "Coins-26")
            items.append(item)
        }
        
        // Opening Hours Cell
        if let hours = place.hours {
            var item = PlaceGeneralCellItem(type: "Hour")
            item.text = hours.map({"\($0.dayText()): \($0.rangeText())"}).joined(separator: "\n")
            item.icon = UIImage(named: "Clock-26")
            items.append(item)
        }
        
        // Phone Icon Label Cell
        if let phone = place.phone {
            var item = PlaceGeneralCellItem(type: "Phone")
            item.text = phone
            item.icon = UIImage(named: "Phone-26")
            items.append(item)
        }
        
        // Address Label Cell
        if let address = place.location?.address {
            var item = PlaceGeneralCellItem(type: "Address")
            item.text = address
            item.icon = UIImage(named: "Map Marker-26")
            items.append(item)
        }
        
        // Deascription Cell
        if let description = place.description {
            var item = PlaceGeneralCellItem(type: "Description")
            item.text = description
            item.icon = UIImage(named: "Info-26")
            items.append(item)
        }
        
        // Finally, reload table view the render the cells
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.row].type {
        case "Menu":
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceGeneralMenuCell", for: indexPath) as! PlaceGeneralMenuCell
            cell.render(menus: place.menus)
            return cell
        default: // All general text cell, render here
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceGeneralTextCell", for: indexPath) as! PlaceGeneralTextCell
            cell.render(item: items[indexPath.row])
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

    }
}

struct PlaceGeneralCellItem {
    let type: String
    
    // Helper parameters for certain items
    var icon: UIImage?
    var text: String?
    
    init(type: String) {
        self.type = type
    }
}

/**
 Abstract general text only table view cell
 */
class PlaceGeneralTextCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var textLabelView: UILabel!

    func render(image: UIImage?, text: String?) {
        iconImageView.image = image
        textLabelView.text = text
    }
    
    func render(item: PlaceGeneralCellItem) {
        render(image: item.icon, text: item.text)
    }
}

/**
 Hour cell is multi line label view
 Dynamaic height
 */
class PlaceGeneralHourCell: UITableViewCell {
    // TODO future
}

/**
 Menu is a special cell with image gallery in 4 of hornzontail view
 Static height
 */
class PlaceGeneralMenuCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var menuCollectionView: UICollectionView!
    @IBOutlet weak var menuFlowLayout: UICollectionViewFlowLayout!

    var needPrepare: Bool = true
    var contentSize: CGSize!
    var menus = [Menu]()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if (needPrepare) {
            self.iconImageView.image = UIImage(named: "Magical Scroll-26")
            self.menuCollectionView.dataSource = self
            self.menuCollectionView.delegate = self
            
            // Calculating content size
            let minSpacing: CGFloat = self.menuFlowLayout.minimumInteritemSpacing
            let width: CGFloat = self.menuCollectionView.frame.width
            let contentWidth = Float(width - minSpacing * 3)/4.0
            self.contentSize = CGSize(width: CGFloat(floorf(contentWidth)), height: 68.0)
            needPrepare = false
        }
    }
    
    func render(menus: [Menu]?) {
        if let menus = menus {
            self.menus = menus
        } else {
            self.menus.removeAll()
        }
        menuCollectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return menus.count > 4 ? 4 : menus.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = menuCollectionView.dequeueReusableCell(withReuseIdentifier: "MenuContentCell", for: indexPath) as! MenuContentCell
        cell.render(menu: menus[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return contentSize
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // TODO on click
    }
}

/**
 Gallery content cell for instagram images
 */
class MenuContentCell: UICollectionViewCell {
    @IBOutlet weak var thumbImageView: UIImageView!
    
    func render(menu: Menu) {
        thumbImageView.sd_setImage(with: menu.thumbImageURL())
    }
}

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
    
    var graphics = [Graphic]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.galleryCollection.dataSource = self
        self.galleryCollection.delegate = self
        
        // Calculating insets, content size and spacing size for flow layout
        let width = galleryCollection.frame.width
        let halfWidth = Float(width - minSpacing * 3)/2.0
        self.contentSize = CGSize(width: CGFloat(floorf(halfWidth)), height: CGFloat(floorf(halfWidth)))
        
        // Apply sizes to flow layout
        self.galleryFlowLayout.sectionInset = UIEdgeInsets(top: 16, left: minSpacing, bottom: 16, right: minSpacing)
        self.galleryFlowLayout.minimumLineSpacing = minSpacing
        self.galleryFlowLayout.minimumInteritemSpacing = floorf(halfWidth) == halfWidth ? minSpacing : minSpacing + 1
        
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if (indexPath.row == 0) {
            return CGSize(width: UIScreen.width - minSpacing * 2, height: 24)
        }
        return contentSize
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
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
    
    func render(graphic: Graphic) {
        galleryImageView.sd_setImage(with: graphic.imageURL())
    }
}

/**
 Place controller for articles from blogger
 in Articles Tab
 */
class PlaceArticleController: PlaceControllers, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    let client = MunchClient()
    
    @IBOutlet weak var articleCollection: UICollectionView!
    @IBOutlet weak var articleFlowLayout: UICollectionViewFlowLayout!
    
    var articles = [Article]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.articleCollection.dataSource = self
        self.articleCollection.delegate = self
        
        // Calculating insets, content size and spacing size for flow layout
        let minSpacing: CGFloat = 20
        let width = articleCollection.frame.width
        let halfWidth = Float(width - minSpacing * 3)/2.0
        
        // Apply sizes to flow layout
        self.articleFlowLayout.itemSize = CGSize(width: CGFloat(floorf(halfWidth)), height: CGFloat(floorf(halfWidth)) * 1.8)
        self.articleFlowLayout.sectionInset = UIEdgeInsets(top: 16, left: minSpacing, bottom: 32, right: minSpacing)
        self.articleFlowLayout.minimumLineSpacing = minSpacing
        self.articleFlowLayout.minimumInteritemSpacing = floorf(halfWidth) == halfWidth ? minSpacing : minSpacing + 1
        
        client.places.articles(id: place.id!){ meta, articles in
            if (meta.isOk()){
                self.articles += articles
                self.articleCollection.reloadData()
            }else{
                self.present(meta.createAlert(), animated: true, completion: nil)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.articleCollection.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return articles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceArticleCell", for: indexPath) as! PlaceArticleCell
        cell.render(article: articles[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}

/**
 Article content cell for blogger content
 */
class PlaceArticleCell: UICollectionViewCell {
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var articleImageView: UIImageView!
    @IBOutlet weak var sumaryLabel: UILabel!
    
    func render(article: Article) {
        authorLabel.text = "@" + article.author!
        articleImageView.sd_setImage(with: article.imageURL())
        sumaryLabel.text = article.summary
    }
}





