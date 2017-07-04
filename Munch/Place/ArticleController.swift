//
//  ArticleController.swift
//  Munch
//
//  Created by Fuxing Loh on 9/4/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import SafariServices

/**
 Place controller for articles from blogger
 in Articles Tab
 */
class PlaceArticleController: PlaceControllers, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SFSafariViewControllerDelegate {
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
        
        client.places.articles(id: place.id!, from: 0, size: 10){ meta, articles in
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
    
    /**
     Present article url with safari view controller modarly
     */
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let url = URL(string: articles[indexPath.row].url!)!
        let safari = SFSafariViewController(url: url)
        safari.delegate = self
        present(safari, animated: true, completion: nil)
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
        authorLabel.text = "@" + article.brand!
        if let image = article.thumbnail {
            articleImageView.render(imageMeta: image)
        }
        sumaryLabel.text = article.title
    }
}

