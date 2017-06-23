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

class DiscoverViewController: UIViewController, MXPagerViewDelegate, MXPagerViewDataSource, MXPageSegueSource {
   
    var pageIndex: Int = 0
    // 0 = LinearCollection, 1 = Filter
    var pageControllers = [Int: UIViewController]()
    @IBOutlet weak var pagerView: MXPagerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pagerView.delegate = self
        pagerView.dataSource = self
        pagerView.transitionStyle = .tab
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Temporary render for testing
        let controller = pageControllers[0] as! DiscoverLinearCollectionController
        controller.render(collections: [
            PlaceCollection(name: "Nearby", query: SearchQuery(), places: [Place(), Place()]),
            PlaceCollection(name: "Healthy Options", query: SearchQuery(), places: [Place(), Place()]),
            PlaceCollection(name: "Cafes", query: SearchQuery(), places: [Place(), Place()]),
            PlaceCollection(name: "Pubs & Bars", query: SearchQuery(), places: [Place(), Place()])])
    }
    
    // MARK: - Pager view delegate
    func pagerView(_ pagerView: MXPagerView, didMoveToPage page: UIView, at index: Int) {
    }
    
    // MARK: - Pager segue source
    func setPageViewController(_ pageViewController: UIViewController, at index: Int) {
        pageControllers[index] = pageViewController
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
}

class DiscoverLinearCollectionController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MXPagerViewDelegate, MXPagerViewDataSource {
    
    let titleFont = UIFont.boldSystemFont(ofSize: 24.0)
    @IBOutlet weak var titleCollection: UICollectionView!
    @IBOutlet weak var pagerView: MXPagerView!
    
    var collectionViews = [DiscoverCollectionView]()
    var collections = [PlaceCollection]()
    var pageIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleCollection.delegate = self
        titleCollection.dataSource = self
        titleCollection.showsHorizontalScrollIndicator = false
        
        pagerView.delegate = self
        pagerView.dataSource = self
        pagerView.transitionStyle = .scroll
    }
    
    func render(collections: [PlaceCollection]) {
        self.collections = collections
        
        // Check if have enough collection views, if not add more
        let need = collections.count - collectionViews.count
        if (need != 0) {
            for _ in 1...need {
                collectionViews.append(DiscoverCollectionView())
            }
        }
        
        // Reload title and pager
        self.titleCollection.reloadData()
        self.pagerView.reloadData()
        
        // Render theses collections
        for i in 0..<collections.count {
            self.collectionViews[i].render(places: collections[i].places)
        }
    }
    
    // MARK: - Linear title Collection
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiscoverCollectionTitleCell", for: indexPath) as! DiscoverCollectionTitleCell
        cell.label.text = collections[indexPath.row].name
        cell.selected(select: pageIndex == indexPath.row)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = collections[indexPath.row].name
        let width = UILabel.textWidth(font: titleFont, text: text)
        return CGSize(width: width + 18, height: 50)
    }
    
    // MARK: - Linear Pager View
    func pagerView(_ pagerView: MXPagerView, didMoveToPage page: UIView, at index: Int) {
        self.pageIndex = index
        titleCollection.reloadData()
        collectionViews[index].reloadData()
    }
    
    func numberOfPages(in pagerView: MXPagerView) -> Int {
        return collections.count
    }
    
    func pagerView(_ pagerView: MXPagerView, viewForPageAt index: Int) -> UIView? {
        return collectionViews[index]
    }
 
    // MARK: - Title animation
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let progress = scrollView.contentOffset.x / scrollView.bounds.size.width
//        print(progress)
    }
}

class DiscoverCollectionView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var places = [Place]()
    let width = UIScreen.main.bounds.width
    
    convenience init() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        self.init(frame: CGRect.zero, collectionViewLayout: layout)
        
        // Setup view, delegate and data source
        self.isScrollEnabled = false
        self.backgroundColor = UIColor.white
        dataSource = self
        delegate = self
        
        // Register theses card for reuse
        let nib = UINib(nibName: "DiscoverCards", bundle: nil)
        self.register(nib, forCellWithReuseIdentifier: "DiscoverPlaceCardView")
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 20.0
    }
    
    func render(places: [Place]) {
        self.places = places
        self.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return places.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiscoverPlaceCardView", for: indexPath) as! DiscoverPlaceCardView
        cell.render(place: places[indexPath.row])
        cell.imageView.kf.setImage(with: URL(string: "https://migrationology.smugmug.com/Singapore-2016/i-fDSC6zr/0/X3/singapore-food-guide-3-X3.jpg"))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.width - 24.0
        return CGSize(width: width, height: width * 0.66667)
    }
}

class DiscoverCollectionTitleCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    
    func selected(select: Bool) {
        if (select) {
            label.textColor = UIColor.black
        } else {
            label.textColor = UIColor.black.withAlphaComponent(0.25)
        }
    }
}

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

