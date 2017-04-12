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

@IBDesignable class MunchSearchField: UITextField {
    
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

/**
 Munch search bar is a duo search bar
 That is used by search controller
 , location search controller
 and field search controller
 */
class MunchSearchBar: UIView {
    @IBOutlet weak var locationSearchField: MunchSearchField!
    @IBOutlet weak var filterSearchField: MunchSearchField!
    
    /**
     Update search bar without another previous search bar
     Return true is text has changed
     false if stays the same
     */
    func update(previous: MunchSearchBar) -> Bool {
        // Check for changes
        let changes = locationSearchField.text != previous.locationSearchField.text ||
        filterSearchField.text != previous.filterSearchField.text
        
        apply(previous: previous)
        return changes
    }

    /**
     Apply update to text from previous search bar
     */
    func apply(previous: MunchSearchBar) {
        locationSearchField.text = previous.locationSearchField.text
        filterSearchField.text = previous.filterSearchField.text
    }
    
    func setDelegate(delegate: UITextFieldDelegate) {
        self.locationSearchField.delegate = delegate
        self.filterSearchField.delegate = delegate
    }
}

class SearchViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var discoverTableView: UITableView!
    @IBOutlet var searchBar: MunchSearchBar!
    var delegate: SearchTableDelegate!
    
    var discoverPlaces = [Place]()
    var selectedIndex: IndexPath!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = SearchTableDelegate(controller: self)
        self.discoverTableView.delegate = self.delegate
        self.discoverTableView.dataSource = self.delegate
        
        self.navigationController?.navigationBar.barStyle = .black
        self.setupFlexibleSearchBar()
        self.searchBar.setDelegate(delegate: self)
        
        self.discover(lat: 1.298788, lng: 103.786759)
    }
    
    func setupFlexibleSearchBar() {
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
     Segue to location or filter search
     */
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if (textField == searchBar.locationSearchField) {
            performSegue(withIdentifier: "segueToLocationSearch", sender: self)
        }else if (textField == searchBar.filterSearchField) {
            performSegue(withIdentifier: "segueToFilterSearch", sender: self)
        }
        return false
    }
    
    /**
     Prepare for segue transition for search bar controller
     Using hero transition
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? SearchBarController {
            controller.previousSearchBar = self.searchBar
            
            self.navigationController!.isHeroEnabled = true
            self.navigationController!.heroNavigationAnimationType = .fade
        }
    }
    
    /**
     Unwind Search
     Check search bar and source search bar for changes
     If there is changes, will do re-search
     */
    @IBAction func unwindSearch(segue: UIStoryboardSegue) {
        if let controller = segue.source as? SearchBarController {
            if (self.searchBar.update(previous: controller.searchBar)) {
                // Chages is search bar, do re-search
                print("Search changed")
            }
        }
    }
}

/**
 Search controller actual search logic
 */
extension SearchViewController {
    var client: MunchClient { return MunchClient.instance }
    
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
        self.controller.navigationController!.isHeroEnabled = false
        self.controller.navigationController!.pushViewController(placeController, animated: true)
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

/**
 Shared search bar controller for location & filter views
 */
class SearchBarController: UIViewController, UITextFieldDelegate {
    var previousController: SearchBarController?
    var previousSearchBar: MunchSearchBar!
    @IBOutlet weak var searchBar: MunchSearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Disable back button
        self.navigationItem.hidesBackButton = true
        // Fixes elipsis bug when multiple segue are chained
        let backBarItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backBarItem
        
        // Setup search bar
        self.searchBar.apply(previous: previousSearchBar)
        self.searchBar.setDelegate(delegate: self)
    }
    
    @IBAction func actionCancel(_ sender: Any) {
        // Un-apply search bar due to cancel
        self.searchBar.apply(previous: previousSearchBar)
        performSegue(withIdentifier: "unwindSearchWithSegue", sender: self)
    }
    
    /**
     User click return button on either search bar
     */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        performSegue(withIdentifier: "unwindSearchWithSegue", sender: self)
        return true
    }
    
    /**
     Prepare for segue transition for search bar controller
     Using hero transition
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? SearchBarController {
            controller.previousController = self
            controller.previousSearchBar = self.searchBar
            
            self.navigationController!.isHeroEnabled = true
            self.navigationController!.heroNavigationAnimationType = .fade
        }
    }
    
    /**
     Text field helper to check if need to transit to another view controller
     */
    func textFieldShouldBeginEditing(_ textField: UITextField, altTextField: UITextField, segue: String) -> Bool {
        if (textField == altTextField) {
            // Check if previous controller is the controller forward
            if let controller = previousController {
                controller.searchBar.apply(previous: self.searchBar)
                hero_dismissViewController()
            }else{
                performSegue(withIdentifier: segue, sender: self)
            }
            return false
        }
        return true
    }
}

class SearchLocationController: SearchBarController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.searchBar.locationSearchField.becomeFirstResponder()
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return textFieldShouldBeginEditing(textField, altTextField: searchBar.filterSearchField, segue: "segueToFilterSearch")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) { // Detect my location section
            return 1
        } else {
            return 2
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) { // Detect my location section
            return nil
        } else {
            return "Recent Locations"
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel!.font = UIFont.boldSystemFont(ofSize: 13)
        header.textLabel!.textColor = UIColor.black.withAlphaComponent(0.7)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.section == 0) {
            return tableView.dequeueReusableCell(withIdentifier: "DetectMyLocationCell") as! DetectMyLocationCell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchLocationTextCell") as! SearchLocationTextCell
        cell.render(title: "Bishan")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO something
    }
}

class DetectMyLocationCell: UITableViewCell {
    var needPrepare = true
    
    @IBOutlet weak var detectLocationButton: UIButton!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if (needPrepare){
            detectLocationButton.layer.cornerRadius = 4.0
            detectLocationButton.layer.borderWidth = 1.0
            detectLocationButton.layer.borderColor = UIColor(hex: "007AFF").cgColor
            needPrepare = false
        }
    }
}

class SearchLocationTextCell: UITableViewCell {
    @IBOutlet weak var locationLabel: UILabel!
    
    func render(title: String) {
        self.locationLabel.text = title
    }
}

class SearchFilterController: SearchBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.searchBar.filterSearchField.becomeFirstResponder()
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return textFieldShouldBeginEditing(textField, altTextField: searchBar.locationSearchField, segue: "segueToLocationSearch")
    }
}

class SearchFilterPopoverController: UIViewController {
    
}
