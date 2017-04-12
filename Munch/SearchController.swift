//
//  DiscoverController.swift
//  Munch
//
//  Created by Fuxing Loh on 23/3/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import SwiftLocation
import Kingfisher

import UIKit
import SnapKit
import Hero

import FlexibleHeightBar

/**
 Search navigation view controller
 */
class SearchNavigationController: UINavigationController {
    
    /**
     View did load will set the selected index to first tab
     This is required due to a bug in ESTabBarItem not allowing NSCoder
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        // Make navigation bar transparent
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        
        // See view did load description
        self.tabBarController?.selectedIndex = 0
    }
    
}

class MunchSearchBar: UISearchBar {
    required init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.backgroundImage = UIImage()
        self.barTintColor = UIColor.clear
        self.tintColor = UIColor.black.withAlphaComponent(0.8)
    }
}

@IBDesignable
class MunchSearchField: UITextField {
    
    // Provides left padding for images
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var textRect = super.leftViewRect(forBounds: bounds)
        textRect.origin.x += leftImagePadding
        textRect.size.width = leftImageWidth
        return textRect
    }
    
    @IBInspectable var leftImagePadding: CGFloat = 0
    @IBInspectable var leftImageWidth: CGFloat = 20
    @IBInspectable var leftImageSize: CGFloat = 18 {
        didSet {
            updateView()
        }
    }
    
    
    @IBInspectable var leftImage: UIImage? {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var color: UIColor = UIColor.lightGray {
        didSet {
            updateView()
        }
    }
    
    func updateView() {
        if let image = leftImage {
            leftViewMode = UITextFieldViewMode.always
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: leftImageSize, height: leftImageSize))
            imageView.contentMode = .scaleAspectFit

            imageView.image = image
            imageView.tintColor = color
            leftView = imageView
        } else {
            leftViewMode = UITextFieldViewMode.never
            leftView = nil
        }
        
        // Placeholder text color
        attributedPlaceholder = NSAttributedString(string: placeholder != nil ?  placeholder! : "", attributes:[NSForegroundColorAttributeName: color])
    }
}


class SearchViewController: UIViewController {
    let client = MunchClient()
    
    @IBOutlet weak var discoverTableView: UITableView!
    @IBOutlet var searchBar: UIView!
    var delegate: SearchTableDelegate!
    
    var discoverPlaces = [Place]()
    var selectedIndex: IndexPath!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = SearchTableDelegate(controller: self)
        self.discoverTableView.delegate = self.delegate
        self.discoverTableView.dataSource = self.delegate
        
        self.navigationController?.navigationBar.barStyle = .black
        self.setupSearchBar()
        
        self.discover(lat: 1.298788, lng: 103.786759)
    }
    
    func setupSearchBar() {
        let height: CGFloat = 154.0
        let flexibleBar = FlexibleHeightBar(frame: CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: height))
        flexibleBar.minimumBarHeight = 64.0
        flexibleBar.maximumBarHeight = height
        
        flexibleBar.backgroundColor = UIColor.primary
        flexibleBar.behaviorDefiner = FacebookBarBehaviorDefiner()
        flexibleBar.addSubview(searchBar)

        // Search bar snaps to flexible bar
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(flexibleBar)
            make.left.equalTo(flexibleBar)
            make.right.equalTo(flexibleBar)
            make.bottom.equalTo(flexibleBar)
        }
        
        self.view.addSubview(flexibleBar)
        self.delegate.otherDelegate = flexibleBar.behaviorDefiner
        self.discoverTableView.contentInset = UIEdgeInsetsMake(height - 64.0, 0.0, 0.0, 0.0)
    }
    
    /**
     Discover local area
     */
    func discover(){
        SwiftLocation.Location.getLocation(accuracy: .block, frequency: .oneShot, success: {
            (_, location)  in
            let lat = location.coordinate.latitude
            let lng = location.coordinate.longitude
            self.discover(lat: lat, lng: lng)
        }) { (_, location, error) in
            let alert = UIAlertController(title: "Location Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    /**
     Discover a defined latitude and longitude
     */
    func discover(lat: Double, lng: Double){
        client.places.discover(spatial: Spatial(lat: lat, lng: lng)){ meta, places in
            if (meta.isOk()){
                self.discoverPlaces.removeAll()
                self.discoverPlaces += places
                self.discoverTableView.reloadData()
            }else{
                self.present(meta.createAlert(), animated: true, completion: nil)
            }
        }
    }
    
    /**
     Custom delegate because scroll view delegate ned to be shared with
     Flexible height bar
     */
    class SearchTableDelegate: TableViewDelegateHandler, UITableViewDataSource {
        let controller: SearchViewController
        
        init(controller: SearchViewController) {
            self.controller = controller
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return controller.discoverPlaces.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverViewCell", for: indexPath) as! DiscoverViewCell
            cell.render(place: controller.discoverPlaces[indexPath.row])
            return cell
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            let storyboard = UIStoryboard(name: "Place", bundle: nil)
            
            let placeController = storyboard.instantiateInitialViewController() as! PlaceViewController
            placeController.place = self.controller.discoverPlaces[indexPath.row]
            self.controller.navigationController?.pushViewController(placeController, animated: true)
        }
    }
}

class DiscoverViewCell: UITableViewCell {
    
    @IBOutlet weak var discoverImageView: UIImageView!
    @IBOutlet weak var placeName: UILabel!

    func render(place: Place) {
        self.placeName.text = place.name!
        if let imageURL = place.imageURL() {
            self.discoverImageView.kf.setImage(with: imageURL)
        }
    }
}
