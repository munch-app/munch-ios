//
//  SearchLocationController.swift
//  Munch
//
//  Created by Fuxing Loh on 18/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class SearchLocationController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: SearchTextField!
    
    var headerView: SearchHeaderView!
    
    var locations: [Location] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 50
        let footerView = UIView(frame: self.view.frame)
        footerView.backgroundColor = UIColor(hex: "F8F8F8")
        self.tableView.tableFooterView = footerView

        registerCell()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textField.resignFirstResponder()
    }
    
    @IBAction func actionCancel(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func textFieldDidChange(_ sender: Any) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.perform(#selector(textFieldDidCommit(text:)), with: textField.text, afterDelay: 0.4)
    }
    
    @objc func textFieldDidCommit(text: String?) {
        if let text = text, text.characters.count >= 3 {
            MunchApi.locations.suggest(text: text) { (meta, locations) in
                self.locations = locations
                self.tableView.reloadData()
            }
        }
    }
}

extension SearchLocationController {
    func registerCell() {
        tableView.register(SearchLocationMyLocationCell.self, forCellReuseIdentifier: SearchLocationMyLocationCell.id)
        tableView.register(SearchLocationTextCell.self, forCellReuseIdentifier: SearchLocationTextCell.id)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return MunchLocation.isEnabled ? 1 : 0
        case 1: return locations.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return "SUGGESTED LOCATION"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.tintColor = UIColor(hex: "F1F1F1")
        header.textLabel!.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightMedium)
        header.textLabel!.textColor = UIColor.black.withAlphaComponent(0.8)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: return tableView.dequeueReusableCell(withIdentifier: SearchLocationMyLocationCell.id)!
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchLocationTextCell.id) as! SearchLocationTextCell
            cell.render(name: locations[indexPath.row].name)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var searchQuery = self.headerView.mainSearchQuery
        switch indexPath.section {
        case 0:
            searchQuery.latLng = MunchLocation.getLatLng()
            break
        default:
            searchQuery.location = locations[indexPath.row]
        }
        
        self.dismiss(animated: true) {
            self.headerView.onHeaderApply(action: .apply(searchQuery))
        }
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
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: UIFontWeightRegular)
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

class SearchLocationTextCell: UITableViewCell {
    let nameLabel = UILabel ()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        nameLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightRegular)
        nameLabel.textColor = .black
        nameLabel.numberOfLines = 1
        nameLabel.textAlignment = .natural
        
        self.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.height.equalTo(21)
            make.left.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(11)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(name: String?) {
        self.nameLabel.text = name
    }
    
    class var id: String {
        return "SearchLocationTextCell"
    }
}
