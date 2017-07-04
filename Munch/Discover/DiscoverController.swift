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
import NVActivityIndicatorView

class DiscoverController: UIViewController, MXPagerViewDelegate, MXPagerViewDataSource, MXPageSegueSource, DiscoverDelegate, SearchNavigationBarDelegate {
    
    var pageIndex: Int = 0
    var pageControllers = [Int: UIViewController]()
    let segues = [
        0: "discover_segue_loading",
        1: "discover_segue_tabs",
        2: "discover_segue_search"
    ]
    
    let placeClient = MunchClient.instance.places
    @IBOutlet weak var searchBar: SearchNavigationBar!
    @IBOutlet weak var pagerView: MXPagerView!
    
    var queryExpiryDate = Date().addingTimeInterval(-6000)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pagerView.delegate = self
        pagerView.dataSource = self
        pagerView.transitionStyle = .tab
        
        searchBar.setDelegate(delegate: self)
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
        
        // Search query have expired
        if (queryExpiryDate < Date()) {
            // Get current Location
            if (MunchLocation.enabled) {
                // Wait for first location update
                MunchLocation.waitFor() { (latLng, err) in
                    if let error = err {
                        self.alert(error: error)
                    } else {
                        // Once successful, just query once
                        self.query(searchQuery: SearchQuery())
                    }
                }
            } else {
                // Location service is not enabled
                self.query(searchQuery: SearchQuery())
            }
        } else {
            // Not yet expire, extend by 30 minutes
            queryExpiryDate = Date().addingTimeInterval(60 * 30)
        }
    }
    
    /**
     Search bar did begin, keyboard appears
     */
    func searchBarDidBegin() {
        pagerView.showPage(at: 2, animated: false)
    }
    
    /**
     Search bar did end, keyboard will dispear now
     Parameter search: true = user clicked on the search button of the keyboard
     */
    func searchBarDidEnd(withSearch search: Bool) {
        pagerView.showPage(at: 1, animated: false)
    }
    
    /**
     Query with SearchQuery
     When querying is in progress, it cannot be queried again
     */
    func query(searchQuery: SearchQuery) {
        pagerView.showPage(at: 0, animated: false)
        placeClient.search(query: searchQuery) { (meta, collections) in
            if (meta.isOk()) {
                // Set query to expiry in 1 hour
                self.queryExpiryDate = Date().addingTimeInterval(60 * 60)
                self.pagerView.showPage(at: 1, animated: false)
                
                let cardCollections = collections.map {CardCollection(name: $0.name, query: $0.query, items: $0.places)}
                (self.pageControllers[1]! as! DiscoverTabController).render(collections: cardCollections)
            } else {
                self.present(meta.createAlert(), animated: true)
            }
        }
        
        // TODO: Update search bar with query also to keep Concurrency, incase of double update
    }
    
    // MARK: - View Pager
    func setPageViewController(_ pageViewController: UIViewController, at index: Int) {
        pageControllers[index] = pageViewController
        
        // Assiocate and link delegate
        if let controller = pageViewController as? DiscoverTabController {
            controller.discoverDelegate = self
        }
    }
    
    func numberOfPages(in pagerView: MXPagerView) -> Int {
        return segues.count
    }
    
    func pagerView(_ pagerView: MXPagerView, viewForPageAt index: Int) -> UIView? {
        // If already exist
        if let page = pageControllers[index] {
            return page.view
        }
        
        // If don't exist, perform it first
        self.pageIndex = index
        self.performSegue(withIdentifier: segues[index]!, sender: nil)
        return pageControllers[index]?.view
    }
    
    // MARK: - Transition to other
    
    /**
     Unwind to main Discover View Controller
     */
    @IBAction func unwindToDiscover(segue: UIStoryboardSegue) {
        
    }
    
    /**
     Wind to place discover view controller
     */
    func present(place: Place) {
        let storyboard = UIStoryboard(name: "Place", bundle: nil)
        let controller = storyboard.instantiateInitialViewController() as! PlaceViewController
        controller.place = place
        
        self.navigationController!.pushViewController(controller, animated: true)
    }
}

protocol DiscoverDelegate {
    /**
     Present place controller with place data
     */
    func present(place: Place)
    
    var searchBar: SearchNavigationBar! { get }
    
    var view: UIView! { get }
}

class StaticDiscoverPageView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        bounds = frame.insetBy(dx: 0, dy: -SearchNavigationBar.diffHeight)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        bounds = frame.insetBy(dx: 0, dy: -SearchNavigationBar.diffHeight)
    }
    
}

class DiscoverLoadingController: UIViewController {
    @IBOutlet weak var indicatorView: NVActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init Loading indicator view
        self.indicatorView.color = .primary700
        self.indicatorView.startAnimating()
    }
}

class SearchNavigationBar: UIView, UITextFieldDelegate {
    enum State {
        case Open
        case Close
    }
    
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var searchBar: DiscoverSearchField!
    
    @IBOutlet weak var actionBtnWidth: NSLayoutConstraint!
    @IBOutlet weak var actionButton: UIButton!
    
    static let maxHeight: CGFloat = 103.0
    static let minHeight: CGFloat = 20.0
    static let diffHeight: CGFloat = 83.0
    static let fieldHeight: CGFloat = 35.0
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    var state = State.Open
    private var delegate: SearchNavigationBarDelegate?
    
    func setDelegate(delegate: SearchNavigationBarDelegate) {
        self.delegate = delegate
        searchBar.delegate = self
    }
    
    /**
     Reset search bar inputs
     */
    func reset() {
        searchBar.text = nil
        locationButton.setTitle("Singapore", for: .normal)
    }
    
    @IBAction func actionTouchUp(_ sender: Any) {
        if (self.actionButton.currentTitle == "Cancel") {
            searchBarWillEnd(withSearch: false)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.3) {
            self.actionButton.setTitle("Cancel", for: .normal)
            self.actionBtnWidth.constant = 65
            self.actionButton.setImage(nil, for: .normal)
            self.layoutIfNeeded()
        }
        
        delegate?.searchBarDidBegin()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchBarWillEnd(withSearch: true)
        return true
    }
    
    func searchBarWillEnd(withSearch: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.actionButton.setTitle(nil, for: .normal)
            self.actionBtnWidth.constant = 45
            self.actionButton.setImage(UIImage(named: "icons8-Horizontal Settings Mixer-30"), for: .normal)
            self.layoutIfNeeded()
        }
        
        searchBar.resignFirstResponder()
        delegate?.searchBarDidEnd(withSearch: withSearch)
    }
    
    
    /**
     Check that navigation bar is open
     */
    func isOpen() -> Bool {
        let currentHeight = heightConstraint.constant
        return currentHeight >= SearchNavigationBar.maxHeight
    }
    
    func shouldOffset() -> CGFloat {
        return SearchNavigationBar.maxHeight - heightConstraint.constant
    }
    
    /**
     return height that the bar should be
     */
    func calculateHeight(relativeY: CGFloat) -> CGFloat {
        if (relativeY > SearchNavigationBar.diffHeight) {
            return SearchNavigationBar.minHeight
        } else if (relativeY < 0) {
            return SearchNavigationBar.maxHeight
        } else {
            return SearchNavigationBar.minHeight + SearchNavigationBar.diffHeight - relativeY
        }
    }
    
    /**
     Update height progress of naivgation bar live
     Update with current y progress
     */
    func updateHeight(relativeY: CGFloat, constraint: NSLayoutConstraint?) {
        // Calculate progress for navigation bar
        let currentHeight = heightConstraint.constant
        let shouldHeight = calculateHeight(relativeY: relativeY)
        
        // Update constant if not the same, height and top constraint
        if (currentHeight != shouldHeight) {
            heightConstraint.constant = shouldHeight
            constraint?.constant = shouldHeight - SearchNavigationBar.minHeight
            
            // Progress, 100% bar fully extended
            var progress = (shouldHeight - SearchNavigationBar.minHeight)/SearchNavigationBar.diffHeight
            progress = progress < 0.2 ? 0 : (progress - 0.3) * 2
            locationButton.alpha = progress
            searchBar.alpha = progress
            actionButton.alpha = progress
        }
    }
    
    func open(constraint: NSLayoutConstraint?) {
        let currentHeight = heightConstraint.constant
        
        // Update constant if not the same, height and top constraint
        if (currentHeight != SearchNavigationBar.maxHeight) {
            heightConstraint.constant = SearchNavigationBar.maxHeight
            constraint?.constant = SearchNavigationBar.diffHeight
            
            // Progress, 100% bar fully extended
            locationButton.alpha = 1.0
            searchBar.alpha = 1.0
            actionButton.alpha = 1.0
        }
    }
    
    func offsetYFromClosest() -> CGFloat {
        let currentHeight = heightConstraint.constant
        if (currentHeight < (SearchNavigationBar.diffHeight / 2) + SearchNavigationBar.minHeight) {
            return currentHeight - SearchNavigationBar.minHeight
        } else {
            return currentHeight - SearchNavigationBar.maxHeight
        }
    }
}

protocol SearchNavigationBarDelegate {
    func searchBarDidBegin()
    
    /**
     Paramaters: search = true if search bar did end with search
     */
    func searchBarDidEnd(withSearch search: Bool)
}

class DiscoverTabController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var discoverDelegate: DiscoverDelegate!
    let placeClient = MunchClient.instance.places
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var tabCollection: UICollectionView!
    @IBOutlet weak var contentCollection: UICollectionView!
    
    var selectedTab = 0
    var collections = [CardCollection]()
    var offsetMemory = [CGPoint]()
    
    /**
     Setup hairline for title view
     Setup delegate and data source for pager and title collection
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabCollection.delegate = self
        self.tabCollection.dataSource = self
        
        self.contentCollection.delegate = self
        self.contentCollection.dataSource = self
    }
    
    // MARK: - Collections
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // Return 0 if there is nothing to render
        return collections.isEmpty ? 0 : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (collectionView == tabCollection) {
            return collections.count
        }
        return cardView(collectionView, numberOfItemsInSection: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if (collectionView == tabCollection) {
            return DiscoverTabTitleCell.width(title: collections[indexPath.row].name)
        }
        return cardView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if (collectionView == tabCollection) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiscoverTabTitleCell", for: indexPath) as! DiscoverTabTitleCell
            cell.render(title: collections[indexPath.row].name, selected: selectedTab == indexPath.row)
            return cell
        }
        
        return cardView(collectionView, cellForItemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if (collectionView == contentCollection) {
            cardView(collectionView, cellIsVisibleAt: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (collectionView == tabCollection) {
            if (self.selectedTab != indexPath.row) {
                // Save old offset
                var oldOffset = contentCollection.contentOffset
                oldOffset.y = oldOffset.y - discoverDelegate.searchBar.shouldOffset()
                offsetMemory[selectedTab] = oldOffset
                
                self.selectedTab = indexPath.row
                self.tabCollection.reloadData()
                
                // Apply offset memory
                var offset = offsetMemory[self.selectedTab]
                offset.y = offset.y + discoverDelegate.searchBar.shouldOffset()
                self.contentCollection.setContentOffset(offset, animated: false)
                self.contentCollection.reloadData()
            }
        } else {
            return cardView(collectionView, didSelectItemAt: indexPath)
        }
    }
    
    // MARK: Scroll control
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView == contentCollection) {
            let actualY = scrollView.contentOffset.y
            discoverDelegate.searchBar.updateHeight(relativeY: actualY, constraint: topConstraint)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // For decelerated scrolling, scrollViewDidEndDecelerating will be called instead
        if (!decelerate && scrollView == contentCollection) {
            contentScrollViewDidStopped()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if (scrollView == contentCollection) {
            contentScrollViewDidStopped()
        }
    }
    
    func contentScrollViewDidStopped() {
        let y = discoverDelegate.searchBar.offsetYFromClosest()
        // If no change, end it
        if (!y.isZero) {
            UIView.animate(withDuration: 0.2) {
                var offset = self.contentCollection.contentOffset
                offset.y = offset.y + y
                self.contentCollection.contentOffset = offset
                self.discoverDelegate.view.layoutIfNeeded()
            }
        }
    }
}

/**
 Title cell for Discovery Page
 */
class DiscoverTabTitleCell: UICollectionViewCell {
    static let titleFont = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightSemibold)
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var indicator: UIView!
    
    func render(title: String, selected: Bool) {
        self.label.text = title.uppercased()
        if (selected) {
            label.textColor = UIColor.black.withAlphaComponent(0.85)
            indicator.backgroundColor = .primary300
        } else {
            label.textColor = UIColor.black.withAlphaComponent(0.35)
            indicator.backgroundColor = .white
        }
    }
    
    class func width(title: String) -> CGSize {
        let width = UILabel.textWidth(font: titleFont, text: title.uppercased())
        return CGSize(width: width + 20, height: 50)
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

