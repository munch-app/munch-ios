//
//  DiscoverFilter.swift
//  Munch
//
//  Created by Fuxing Loh on 22/6/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class LocationDiscoverPopover: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
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
            return tableView.dequeueReusableCell(withIdentifier: "LocationDetectMyCell") as! LocationDetectMyCell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationTextCell") as! LocationTextCell
        cell.render(title: "Bishan")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO something
    }
}

class LocationDetectMyCell: UITableViewCell {
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

class LocationTextCell: UITableViewCell {
    @IBOutlet weak var locationLabel: UILabel!
    
    func render(title: String) {
        self.locationLabel.text = title
    }
}
