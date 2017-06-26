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
import SafariServices

class DiscoverController: UIViewController, MXPagerViewDelegate, MXPagerViewDataSource, MXPageSegueSource, DiscoverDelegate {
   
    var pageIndex: Int = 0
    // 0 = LinearCollection, 1 = Filter
    var pageControllers = [Int: UIViewController]()
    @IBOutlet weak var searchBar: SearchNavigationBar!
    @IBOutlet weak var pagerView: MXPagerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pagerView.delegate = self
        pagerView.dataSource = self
        pagerView.transitionStyle = .tab
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Temporary render for testing
        let controller = pageControllers[0] as! DiscoverTabController
        controller.render(collections: [
            PlaceCollection(name: "NEARBY", query: SearchQuery(), places: [Place(), Place(), Place()]),
            PlaceCollection(name: "HEALTHY OPTIONS", query: SearchQuery(), places: [Place(), Place()]),
            PlaceCollection(name: "CAFES", query: SearchQuery(), places: [Place(), Place()]),
            PlaceCollection(name: "PUBS & BARS", query: SearchQuery(), places: [Place(), Place()])
        ])
    }
    
    // MARK: - Pager view delegate
    func pagerView(_ pagerView: MXPagerView, didMoveToPage page: UIView, at index: Int) {
    }
    
    // MARK: - Pager segue source
    func setPageViewController(_ pageViewController: UIViewController, at index: Int) {
        pageControllers[index] = pageViewController
        if (index == 0) {
            (pageControllers[0] as! DiscoverTabController).discoverDelegate = self
        }
    }
    
    // MARK: - Pager view data source
    func numberOfPages(in pagerView: MXPagerView) -> Int {
        return 2
    }
    
    func pagerView(_ pagerView: MXPagerView, viewForPageAt index: Int) -> UIView? {
        if let page = pageControllers[index] {
            return page.view
        }
        
        // If don't exist, perform it first
        let identifier = "mx_page_\(index)"
        self.pageIndex = index
        self.performSegue(withIdentifier: identifier, sender: nil)
        return pageControllers[index]?.view
    }
    
    /**
     Unwind to main Discover View Controller
     */
    @IBAction func unwindToDiscover(segue: UIStoryboardSegue) {
        
    }
    
    /**
     Wind to place discover view controller
     */
    func present(place: Place) {
//        let storyboard = UIStoryboard(name: "Place", bundle: nil)
//        let controller = storyboard.instantiateInitialViewController()!
    }
}

class SearchNavigationBar: UIView {
    enum State {
        case Open
        case Close
    }
    
    let maxHeight: CGFloat = 103.0
    let minHeight: CGFloat = 20.0
    let diffHeight: CGFloat = 83.0
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    var state = State.Open
    
    /**
     Check that navigation bar is open
     */
    func isOpen() -> Bool {
        return state == .Open
    }
    
    /**
     return height that the bar should be
     */
    func calculateHeight(relativeY: CGFloat) -> CGFloat {
        if (relativeY > diffHeight) {
            return minHeight
        } else if (relativeY < 0) {
            return maxHeight
        } else {
            return minHeight + diffHeight - relativeY
        }
    }
    
    /**
     Update height progress of naivgation bar live
     Update with current y progress
     */
    func updateHeight(relativeY: CGFloat, constraint: NSLayoutConstraint? = nil) {
        // Calculate progress for navigation bar
        let currentHeight = heightConstraint.constant
        let shouldHeight = calculateHeight(relativeY: relativeY)
        // Progress, 100% bar fully extended
//        let progress: shouldHeight/diffHeight
        
        // Update constant if not the same, height and top constrait
        if (currentHeight != shouldHeight) {
            heightConstraint.constant = shouldHeight
            constraint?.constant = shouldHeight - minHeight
        }
    }

    /**
     UI animate height of navigation bar
     */
    func animateHeight(to state: State) {
        
    }
}

protocol DiscoverDelegate {
    /**
     Present place controller with place data
     */
    func present(place: Place)
    
    var searchBar: SearchNavigationBar! { get }
}


class DiscoverTabController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var discoverDelegate: DiscoverDelegate!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var tabView: UIView!
    @IBOutlet weak var tabCollection: UICollectionView!
    @IBOutlet weak var contentCollection: UICollectionView!
    
    var selectedTab = 0
    var collections = [PlaceCollection]()
    var lastEndScrollY: CGFloat = 0 // Updated once end dragging
    
    /**
     Setup hairline for title view
     Setup delegate and data source for pager and title collection
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabView.hairlineShadow()
        self.tabCollection.delegate = self
        self.tabCollection.dataSource = self
        
        self.contentCollection.delegate = self
        self.contentCollection.dataSource = self
    }
    
    /**
     Dynamically load new collection view if need to
     */
    func render(collections: [PlaceCollection]) {
        self.collections = collections
        // Reload title and selected tabs
        self.tabCollection.reloadData()
        // Must select tab before reload
        self.selectedTab = 0
        self.contentCollection.reloadData()
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
        return collections[selectedTab].places.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if (collectionView == tabCollection) {
            return DiscoverTabTitleCell.width(title: collections[indexPath.row].name)
        }
        
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: width * 0.9)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if (collectionView == tabCollection) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiscoverTabTitleCell", for: indexPath) as! DiscoverTabTitleCell
            cell.render(title: collections[indexPath.row].name, selected: selectedTab == indexPath.row)
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiscoverPlaceCardView", for: indexPath) as! DiscoverPlaceCardView
        cell.render(place: collections[selectedTab].places[indexPath.row])
        cell.imageView.kf.setImage(with: URL(string: "https://migrationology.smugmug.com/Singapore-2016/i-fDSC6zr/0/X3/singapore-food-guide-3-X3.jpg"))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (collectionView == tabCollection) {
            self.selectedTab = indexPath.row
            self.tabCollection.reloadData()
            self.contentCollection.reloadData()
        } else {
            discoverDelegate.present(place: collections[selectedTab].places[indexPath.row])
        }
    }
    
    // MARK: Scroll control
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView == tabCollection) { return }
        let actualY = scrollView.contentOffset.y
        if (discoverDelegate.searchBar.isOpen()) {
            // Is open now
            discoverDelegate.searchBar.updateHeight(relativeY: actualY - lastEndScrollY, constraint: topConstraint)
            
        } else {
            // Is closed now
            discoverDelegate.searchBar.updateHeight(relativeY: actualY, constraint: topConstraint)
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if (scrollView == tabCollection) { return }
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

