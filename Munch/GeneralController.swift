//
//  GeneralController.swift
//  Munch
//
//  Created by Fuxing Loh on 9/4/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
//import NYTPhotoViewer

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
            item.text = HourFormatter.format(hours: hours)
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
            var item = PlaceGeneralCellItem(type: "Address", selectionStyle: .blue)
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
        
        // Row action
        switch items[indexPath.row].type {
        case "Address":
            if let address = place.location?.address {
                openMaps(address: address)
            }
        default:
            break
        }
    }
    
    func openMaps(address: String) {
        let address = address.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if (UIApplication.shared.canOpenURL(URL(string:"http://maps.apple.com/")!)){
            let appleMapAction = UIAlertAction(title: "Apple Maps", style: .default) { alert in
                UIApplication.shared.open(URL(string:"http://maps.apple.com/?daddr=" + address)!)
            }
            actionSheet.addAction(appleMapAction)
        }
        
        if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
            let googleMapAction = UIAlertAction(title: "Google Maps", style: .default) { alert in
                UIApplication.shared.open(URL(string:"comgooglemaps://?daddr=" + address)!)
            }
            actionSheet.addAction(googleMapAction)
        }
        
        //        if (UIApplication.shared.canOpenURL(URL(string:"waze://")!)) {
        //            let wazeMapAction = UIAlertAction(title: "Waze", style: .default) { alert in
        //
        //            }
        //            actionSheet.addAction(wazeMapAction)
        //        }
        
        // Present action sheet for user to choose map provider
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion:nil)
    }
}

struct PlaceGeneralCellItem {
    let type: String
    let selectionStyle: UITableViewCellSelectionStyle
    
    // Helper parameters for certain items
    var icon: UIImage?
    var text: String?
    
    init(type: String, selectionStyle: UITableViewCellSelectionStyle = .none) {
        self.type = type
        self.selectionStyle = selectionStyle
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
        self.selectionStyle = item.selectionStyle
    }
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
    
    /**
     Render, only filter images to render
     */
    func render(menus: [Menu]?) {
        if let menus = menus {
            self.menus = menus.filter({$0.type == .Image})
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
        //        let photosViewController = NYTPhotosViewController(photos: self.photos)
        //        photosViewController.delegate = self
        //        presentViewController(photosViewController, animated: true, completion: nil)
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
