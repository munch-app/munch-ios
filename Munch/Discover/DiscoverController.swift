//
//  DiscoverController.swift
//  Munch
//
//  Created by Fuxing Loh on 21/6/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import MXPagerView

class DiscoverController: UIViewController, MXPagerViewDelegate, MXPagerViewDataSource, MXPageSegueSource {

    // MARK: - Pager View
    class SeguePage {
        static let loading = 0
        static let tabs = 1
        static let search = 2
        static let no_results = 3
        static let tabless = 4
        
        static let pages = [
            loading: "discover_segue_loading",
            tabs: "discover_segue_tabs",
            search: "discover_segue_search",
            no_results: "discover_segue_no_results",
            tabless: "discover_segue_tabless"
        ]
    }
    var pageIndex: Int = 0
    var pageControllers = [Int: UIViewController]()
    
    @IBOutlet weak var searchBar: SearchNavigationBar!
    @IBOutlet weak var pagerView: MXPagerView!
    
    var collections = [CardCollection]()
    var currentSearchQuery = SearchQuery()
    var queryExpiryDate = Date().addingTimeInterval(-60 * 100)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pagerView.delegate = self
        pagerView.dataSource = self
        pagerView.transitionStyle = .tab
        
        searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (currentSearchQuery != searchBar.searchQuery) {
            // Apply search due to change
            self.query()
        } else {
            // Else check if query has expired
            self.refreshExpiredQuery()
        }
    }
    
    // MARK: - View Pager
    func setPageViewController(_ pageViewController: UIViewController, at index: Int) {
        pageControllers[index] = pageViewController
        
        // Assiocate and link delegate
        if var controller = pageViewController as? ContainDiscoverDelegate {
            controller.discoverDelegate = self
        }
    }
    
    func numberOfPages(in pagerView: MXPagerView) -> Int {
        return SeguePage.pages.count
    }
    
    func pagerView(_ pagerView: MXPagerView, viewForPageAt index: Int) -> UIView? {
        // If already exist
        if let page = pageControllers[index] {
            return page.view
        }
        
        // If don't exist, perform it first
        self.pageIndex = index
        self.performSegue(withIdentifier: SeguePage.pages[index]!, sender: nil)
        return pageControllers[index]?.view
    }
    
    // MARK: - Transition to other
    /**
     Unwind to main Discover View Controller
     */
    @IBAction func unwindToDiscover(segue: UIStoryboardSegue) {
    }
    
    /**
     Storyboard segue prepares for LocationDiscover & FilterDiscover
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigation = segue.destination as? UINavigationController {
            if let controller = navigation.topViewController as? LocationDiscoverPopover {
                controller.discoverDelegate = self
            }
        }
    }
}

/**
 All query related functions for DiscoverController
 */
extension DiscoverController {
    /**
     Check if query has expired, if so, refresh
     */
    func refreshExpiredQuery() {
        // Search query have expired
        if (queryExpiryDate < Date()) {
            // Get current Location
            if (MunchLocation.enabled) {
                // Wait for first location update
                MunchLocation.waitFor() { (latLng, err) in
                    if let error = err {
                        self.alert(error: error)
                    } else {
                        self.query()
                    }
                }
            } else {
                // Location service is not enabled
                self.query()
            }
        } else {
            // Not yet expire, extend by 30 minutes
            queryExpiryDate = Date().addingTimeInterval(60 * 30)
        }
    }
    
    /**
     Query with SearchQuery taken from SearchBar
     When querying is in progress, it cannot be queried again
     */
    func query() {
        let searchQuery = self.searchBar.searchQuery
        self.currentSearchQuery = searchQuery
        pagerView.showPage(at: SeguePage.loading, animated: false)
        
        MunchApi.discovery.search(query: searchQuery) { (meta, collections, streetName) in
            if (meta.isOk()) {
                // Set query to expiry in 1 hour
                self.queryExpiryDate = Date().addingTimeInterval(60 * 60)
                
                // Render it
                self.render(collections: collections.map { CardCollection(collection: $0) })
                
                // Update search bar with query also to keep Concurrency, incase of double update
                self.searchBar.apply(searchQuery: searchQuery, streetName: streetName)
                
            } else {
                self.present(meta.createAlert(), animated: true)
            }
        }
    }
    
    func render(collections: [CardCollection]) {
        self.collections = collections
        
        // Add no result or no location card view
        for collection in collections {
            if (collection.query == nil && collection.items.isEmpty) {
                // Collection with no query and items: Add no result card
                collection.botItems.append(StaticNoResultCardItem())
            } else if (collection.query != nil) {
                // Collection with query: Add loading card view
                collection.botItems.append(StaticLoadingCardItem())
            }
        }
        
        // Add no location card to first collection if available
        if (!collections.isEmpty && !MunchLocation.enabled) {
            collections[0].topItems.insert(StaticNoLocationCardItem(), at: 0)
        }
        
        let pageType = collectionPageType
        pagerView.showPage(at: pageType, animated: false)
        (pageControllers[pageType] as! CollectionController).render(collections: collections)
    }
    
    /**
     Get which page to show based on collections count
     */
    var collectionPageType: Int {
        switch(collections.count) {
        case 0: return SeguePage.no_results
        case 1: return SeguePage.tabless
        default: return SeguePage.tabs
        }
    }
}

// Search Navigation Bar Delegate
extension DiscoverController: SearchNavigationBarDelegate {
    /**
     Search bar did begin, keyboard appears
     */
    func searchDidBegin() {
        pagerView.showPage(at: SeguePage.search, animated: false)
    }
    
    /**
     Search bar did end, keyboard will dispear now
     Parameter search: true = user clicked on the search button of the keyboard
     */
    func searchDidEnd(withReturn search: Bool) {
        if (search) {
            // User Clicked on Search Button
            self.searchBar.searchQuery.query = self.searchBar.searchField.text
            self.query()
            pagerView.showPage(at: SeguePage.loading, animated: false)
        } else if (self.currentSearchQuery != self.searchBar.searchQuery) {
            // User edited search query via other methods
            self.query()
            pagerView.showPage(at: SeguePage.loading, animated: false)
        } else {
            // User Clicked on Cancel
            self.searchBar.apply(searchQuery: currentSearchQuery)
            pagerView.showPage(at: collectionPageType, animated: false)
        }
    }
}

// Discover Delegate Implemention on Discover Controller
extension DiscoverController: DiscoverDelegate {
    /**
     Wind to place discover view controller
     */
    func present(place: Place) {
        let storyboard = UIStoryboard(name: "Place", bundle: nil)
        let controller = storyboard.instantiateInitialViewController() as! PlaceViewController
        controller.place = place
        
        self.navigationController!.pushViewController(controller, animated: true)
    }
    
    /**
     Collection view did scroll
     */
    func collectionViewDidScroll(_ scrollView: UIScrollView) {
        let actualY = scrollView.contentOffset.y
        searchBar.updateHeight(relativeY: actualY)
    }
    
    /**
     Scroll view did finishing scrolling
     */
    func collectionViewDidScrollFinish(_ scrollView: UIScrollView) {
        let y = searchBar.diffFromNearestY
        // If no change, end it
        if (!y.isZero) {
            UIView.animate(withDuration: 0.2) {
                var offset = scrollView.contentOffset
                offset.y = offset.y + y
                scrollView.contentOffset = offset
                self.view.layoutIfNeeded()
            }
        }
    }
    
    var headerHeight: CGFloat {
        return SearchNavigationBar.maxHeight
    }
}

protocol DiscoverDelegate {
    /**
     Present place controller with place data
     For tabs, tabless and search controllers
     */
    func present(place: Place)
    
    /**
     Collection view did scroll
     */
    func collectionViewDidScroll(_ scrollView: UIScrollView)
    
    /**
     Collection view did scroll finsish, stopped
     */
    func collectionViewDidScrollFinish(_ scrollView: UIScrollView)

    /**
     Return the search navigation bar
     */
    var searchBar: SearchNavigationBar! { get }
    
    /**
     Height of header bar
     */
    var headerHeight: CGFloat { get }
}

protocol SearchNavigationBarDelegate {
    func searchDidBegin()
    
    /**
     Paramaters: search = true if search bar did end with search
     */
    func searchDidEnd(withReturn search: Bool)
}

class SearchNavigationBar: UIView, UITextFieldDelegate {
    var delegate: SearchNavigationBarDelegate!
    
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var searchField: DiscoverSearchField!
    @IBOutlet weak var actionBtnWidth: NSLayoutConstraint!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    static let maxHeight: CGFloat = 103.0
    static let minHeight: CGFloat = 20.0
    static let diffHeight: CGFloat = 83.0
    
    var searchQuery = SearchQuery()
    
    // MARK: - Click Actions
    override func layoutSubviews() {
        super.layoutSubviews()
        self.searchField.delegate = self
    }
    
    @IBAction func actionTouchUp(_ sender: Any) {
        if (self.actionButton.currentTitle == "Cancel") {
            searchBarWillEnd(withReturn: false)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.3) {
            self.actionButton.setTitle("Cancel", for: .normal)
            self.actionBtnWidth.constant = 65
            self.actionButton.setImage(nil, for: .normal)
            self.layoutIfNeeded()
        }
        
        delegate.searchDidBegin()
    }
    
    func searchBarWillEnd(withReturn search: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.actionButton.setTitle(nil, for: .normal)
            self.actionBtnWidth.constant = 45
            self.actionButton.setImage(UIImage(named: "icons8-Horizontal Settings Mixer-30"), for: .normal)
            self.layoutIfNeeded()
        }
        
        searchField.resignFirstResponder()
        delegate.searchDidEnd(withReturn: search)
    }
}

// Height operations for navigation bar
extension SearchNavigationBar {
    var height: CGFloat {
        return heightConstraint.constant
    }
    
    /**
     Distance from nearest open or close
     */
    var diffFromNearestY: CGFloat {
        let currentHeight = height
        if (currentHeight < (SearchNavigationBar.diffHeight / 2) + SearchNavigationBar.minHeight) {
            return currentHeight - SearchNavigationBar.minHeight
        } else {
            return currentHeight - SearchNavigationBar.maxHeight
        }
    }
    
    /**
     Check if the bar is fully closed
     */
    var isFullyClosed: Bool {
        return height == SearchNavigationBar.minHeight
    }
    
    /**
     Check if the bar is fully opened
     */
    var isFullyOpened: Bool {
        return height == SearchNavigationBar.maxHeight
    }
    
    /**
     Calculate height that the search bar should be based on the
     Scroll position of relative y
     */
    func calculateHeight(relativeY: CGFloat) -> CGFloat {
        if (relativeY >= SearchNavigationBar.diffHeight) {
            return SearchNavigationBar.minHeight
        } else if (relativeY <= 0) {
            return SearchNavigationBar.maxHeight
        } else {
            return SearchNavigationBar.minHeight + SearchNavigationBar.diffHeight - relativeY
        }
    }
    
    /**
     Update height progress of naivgation bar live
     Update with current y progress
     */
    func updateHeight(relativeY: CGFloat) {
        // Calculate progress for navigation bar
        let currentHeight = heightConstraint.constant
        let shouldHeight = calculateHeight(relativeY: relativeY)
        
        // Update constant if not the same, height and top constraint
        if (currentHeight != shouldHeight) {
            heightConstraint.constant = shouldHeight
            
            // Progress, 100% bar fully extended
            var progress = (shouldHeight - SearchNavigationBar.minHeight) / SearchNavigationBar.diffHeight
            progress = progress < 0.2 ? 0 : (progress - 0.3) * 2
            locationButton.alpha = progress
            searchField.alpha = progress
            actionButton.alpha = progress
        }
    }
}

// Apply and Reset functions for navigation bar
extension SearchNavigationBar {
    /**
     Reset search bar
     */
    func reset() {
        apply(searchQuery: SearchQuery(), streetName: nil)
    }
    
    /**
     Apply search bar from results of munch-api
     searchQuery: SearchQuery
     streetName: String
     */
    func apply(searchQuery: SearchQuery, streetName: String?) {
        apply(searchQuery: searchQuery)
        
        // Applying Location Name
        if let location = searchQuery.location {
            // Using Defined Polygon Location
            if let name = location.name {
                locationButton.setTitle(name, for: .normal)
            } else {
                locationButton.setTitle("Defined Location", for: .normal)
            }
        } else if (MunchLocation.enabled) {
            // Using implicit Location
            if let streetName = streetName {
                locationButton.setTitle(streetName, for: .normal)
            } else {
                locationButton.setTitle("Current Location", for: .normal)
            }
        } else {
            locationButton.setTitle("Singapore", for: .normal)
        }
    }
    
    /**
     Apply only search bar but not location name
     */
    func apply(searchQuery: SearchQuery) {
        self.searchQuery = searchQuery
        searchField.text = searchQuery.query
    }
    
    /**
     Apply search bar with location for DiscoverPopover.LocationController
     location: Location, nil = currentLocation
     */
    func apply(location: Location?) {
        self.searchQuery.location = location
        apply(searchQuery: self.searchQuery, streetName: nil)
    }
}

/**
 Designable search field for Discovery page
 */
@IBDesignable class DiscoverSearchField: UITextField {
    
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
