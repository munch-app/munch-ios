//
//  SearchControllerSuggest.swift
//  Munch
//
//  Created by Fuxing Loh on 18/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class SearchQueryController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var searchQuery: SearchQuery!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: SearchTextField!
    
    var results: [SearchResult]?
    var items: [Any] {
        if let results = results {
            return results
        }
        
        // TODO Returns results from, Implement in 0.2.0 onwards
        return []
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        if results == nil {
            textField.becomeFirstResponder()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if results != nil {
            textField.becomeFirstResponder()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 50
        
        let footerView = UIView(frame: CGRect.zero)
        self.tableView.tableFooterView = footerView
        self.tableView.contentInset.top = 0
        
        self.textField.text = self.searchQuery.query
        self.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.textField.addTarget(self, action: #selector(textFieldShouldReturn(_:)), for: .editingDidEndOnExit)
        registerCell()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textField.resignFirstResponder()
    }
    
    @IBAction func actionCancel(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @objc func textFieldDidChange(_ sender: Any) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.perform(#selector(textFieldDidCommit(text:)), with: textField.text, afterDelay: 0.4)
    }
    
    @objc func textFieldShouldReturn(_ sender: Any) -> Bool {
        if let text = textField.text {
            self.dismiss(animated: true) {
                var query = self.searchQuery!
                query.query = text
                // TODO Action After
            }
        }
        return true
    }
    
    @objc func textFieldDidCommit(text: String?) {
        if let text = text, text.count >= 3 {
            MunchApi.search.suggest(text: text, size: 20, callback: { (meta, results) in
                self.results = results
                self.tableView.reloadData()
            })
        } else {
            results = nil
            self.tableView.reloadData()
        }
    }
}

extension SearchQueryController {
    func registerCell() {
        tableView.register(SearchQueryCell.self, forCellReuseIdentifier: SearchQueryCell.id)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if results != nil {
            return "SUGGESTIONS"
        }
        return "RECENT SEARCH"
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.tintColor = UIColor(hex: "F1F1F1")
        header.textLabel!.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.medium)
        header.textLabel!.textColor = UIColor.black.withAlphaComponent(0.8)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchQueryCell.id) as! SearchQueryCell
        let item = items[indexPath.row]
        
        if let place = item as? Place {
            cell.render(title: place.name, type: "PLACE")
        } else if let location = item as? Location {
            cell.render(title: location.name, type: "LOCATION")
        } else if let tag = item as? Tag {
            cell.render(title: tag.name, type: "TAG")
        } else {
            cell.render(title: nil, type: nil)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        
        if let place = item as? Place {
            let storyboard = UIStoryboard(name: "Place", bundle: nil)
            let controller = storyboard.instantiateInitialViewController() as! PlaceViewController
            controller.placeId = place.id
            self.navigationController!.pushViewController(controller, animated: true)
        } else if let location = item as? Location {
            self.dismiss(animated: true) {
                var query = self.searchQuery!
                query.location = location

                // TODO Action After
            }
        } else if let tag = item as? Tag {
            self.dismiss(animated: true) {
                var query = self.searchQuery!
                query.query = tag.name

                // TODO Action After
            }
        }
    }
}

class SearchQueryCell: UITableViewCell {
    let titleLabel = UILabel()
    let typeLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        titleLabel.textColor = .black
        self.addSubview(titleLabel)
        
        typeLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        typeLabel.textColor = UIColor(hex: "686868")
        typeLabel.textAlignment = .right
        self.addSubview(typeLabel)
        
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self).inset(24)
            make.right.equalTo(self).inset(8)
            make.top.bottom.equalTo(self).inset(11)
        }
        
        typeLabel.snp.makeConstraints { (make) in
            make.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(11)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(title: String?, type: String?) {
        self.titleLabel.text = title
        self.typeLabel.text = type
    }
    
    class var id: String {
        return "SearchQueryCell"
    }
}

class SearchLocationMyLocationCell: UITableViewCell {
    let button = UIButton()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor(hex: "F1F1F1")
        
        button.isEnabled = false
        button.backgroundColor = .white
        button.contentHorizontalAlignment = .left
        button.contentVerticalAlignment = .center
        
        // Setup Image
        button.setImage(UIImage(named: "SC-Define Location-30"), for: .normal)
        button.imageEdgeInsets.left = 10
        button.imageEdgeInsets.right = 10
        button.tintColor = UIColor.secondary
        
        // Setup Text
        button.setTitle("Detect my current location", for: .normal)
        button.setTitleColor(UIColor.secondary, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
        button.titleEdgeInsets.left = 20
        
        // Set Button Layer
        button.layer.cornerRadius = 4.0
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor.secondary.cgColor
        self.addSubview(button)
        
        button.snp.makeConstraints { make in
            make.height.equalTo(38)
            make.left.right.equalTo(self).inset(24)
            make.top.equalTo(self).inset(14)
            make.bottom.equalTo(self).inset(8)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class var id: String {
        return "SearchLocationMyLocationCell"
    }
}

/**
 Designable search field for Discovery page
 */
@IBDesignable class SearchTextField: UITextField {
    
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
        attributedPlaceholder = NSAttributedString(string: placeholder != nil ?  placeholder! : "", attributes:[NSAttributedStringKey.foregroundColor: color])
    }
}
