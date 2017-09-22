//
//  PlaceBasicCards.swift
//  Munch
//
//  Created by Fuxing Loh on 8/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import MapKit

import SnapKit
import SwiftRichString

class PlaceBasicImageBannerCard: UITableViewCell, PlaceCardView {
    let imageGradientView = UIView()
    let imageBannerView = ShimmerImageView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        self.addSubview(imageBannerView)
        
        imageBannerView.snp.makeConstraints { make in
            make.height.equalTo(260).priority(999)
            make.edges.equalTo(self).inset(UIEdgeInsets(top: 0, left: 0, bottom: topBottom, right: 0))
        }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 64)
        gradientLayer.colors = [UIColor.black.withAlphaComponent(0.4).cgColor, UIColor.clear.cgColor]
        imageGradientView.layer.insertSublayer(gradientLayer, at: 0)
        imageGradientView.backgroundColor = UIColor.clear
        self.addSubview(imageGradientView)
        
        imageGradientView.snp.makeConstraints { make in
            make.height.equalTo(64)
            make.top.equalTo(self)
            make.left.equalTo(self)
            make.right.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: PlaceCard) {
        let imageMeta = card["images"][0]["imageMeta"]
        if (imageMeta.exists()) {
            imageBannerView.render(imageMeta: ImageMeta(json: imageMeta))
        }
    }
    
    static var cardId: String {
        return "basic_ImageBanner_15092017"
    }
}

class PlaceBasicNameTagCard: UITableViewCell, PlaceCardView {
    let nameLabel = UILabel()
    let tagsLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        nameLabel.font = UIFont.systemFont(ofSize: 27.0, weight: UIFont.Weight.medium)
        nameLabel.textColor = UIColor.black.withAlphaComponent(0.9)
        nameLabel.numberOfLines = 0
        self.addSubview(nameLabel)
        
        tagsLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.regular)
        tagsLabel.textColor = UIColor.black.withAlphaComponent(0.75)
        tagsLabel.numberOfLines = 1
        self.addSubview(tagsLabel)
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(self).inset(topBottom)
            make.left.right.equalTo(self).inset(leftRight)
        }
        
        tagsLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).inset(0)
            make.left.right.equalTo(self).inset(leftRight)
            make.bottom.equalTo(self).inset(topBottom)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: PlaceCard) {
        self.nameLabel.text = card["name"].string
        let tags = card["tags"].arrayValue.map { $0.stringValue.capitalized }
        self.tagsLabel.text = tags.joined(separator: ", ")
    }
    
    static var cardId: String {
        return "basic_NameTag_12092017"
    }
}

class PlaceBasicBusinessHourCard: UITableViewCell, PlaceCardView {
    static let openStyle = Style("open", {
        $0.color = UIColor.secondary
    })
    static let closeStyle = Style("close", {
        $0.color = UIColor.primary
    })
    
    let grid = UIView()
    let openLabel = UILabel()
    let dayView = DayView()
    
    var openHeightConstraint: Constraint!
    var dayHeightConstraint: Constraint!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        self.addSubview(grid)
        grid.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)
        }
        
        grid.addSubview(openLabel)
        openLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.regular)
        openLabel.numberOfLines = 2
        openLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(grid)
            make.left.right.equalTo(grid)
        }
        
        grid.addSubview(dayView)
        dayView.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: PlaceCard) {
        let hours = BusinessHour(hours: card["hours"].flatMap { Place.Hour(json: $0.1) })
        self.dayView.render(hours: hours)
        
        if hours.isOpen() {
            openLabel.attributedText = "Open Now\n".set(style: PlaceBasicBusinessHourCard.openStyle) + hours.today
        } else {
            openLabel.attributedText = "Closed Now\n".set(style: PlaceBasicBusinessHourCard.closeStyle) + hours.today
        }
    }
    
    func didTap(card: PlaceCard) {
        dayView.isHidden = !dayView.isHidden
        openLabel.isHidden = !openLabel.isHidden
        
        if (openLabel.isHidden) {
            openLabel.snp.removeConstraints()
            dayView.snp.makeConstraints { (make) in
                make.top.bottom.equalTo(grid)
                make.left.right.equalTo(grid)
                make.height.equalTo(44 * 7)
            }
        }
        
        if (dayView.isHidden){
            dayView.snp.removeConstraints()
            openLabel.snp.makeConstraints { (make) in
                make.top.bottom.equalTo(grid)
                make.left.right.equalTo(grid)
            }
        }
    }
    
    static var cardId: String {
        return "basic_BusinessHour_07092017"
    }
    
    class DayView: UIView {
        let dayLabels = [UILabel(), UILabel(), UILabel(), UILabel(), UILabel(), UILabel(), UILabel()]
        
        override init(frame: CGRect = CGRect.zero) {
            super.init(frame: frame)
            self.clipsToBounds = true
            
            for (index, label) in dayLabels.enumerated() {
                label.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.regular)
                label.numberOfLines = 2
                self.addSubview(label)

                label.snp.makeConstraints { make in
                    make.left.right.equalTo(self)
                    make.height.equalTo(44)
                    
                    if index == 0 {
                        make.top.equalTo(self)
                    } else {
                        make.top.equalTo(dayLabels[index-1].snp.bottom)
                    }
                }
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func render(hours: BusinessHour) {
            func createLine(day: String, dayText: String) -> NSAttributedString {
                if hours.isToday(day: day) {
                    if hours.isOpen() {
                        return "\(dayText)\n" + hours[day].set(style: PlaceBasicBusinessHourCard.openStyle)
                    } else {
                        return "\(dayText)\n" + hours[day].set(style: PlaceBasicBusinessHourCard.closeStyle)
                    }
                } else {
                    return NSAttributedString(string: "\(dayText)\n\(hours[day])")
                }
            }
            
            dayLabels[0].attributedText = createLine(day: "mon", dayText: "Monday")
            dayLabels[1].attributedText = createLine(day: "tue", dayText: "Tuesday")
            dayLabels[2].attributedText = createLine(day: "wed", dayText: "Wednesday")
            dayLabels[3].attributedText = createLine(day: "thu", dayText: "Thursday")
            dayLabels[4].attributedText = createLine(day: "fri", dayText: "Friday")
            dayLabels[5].attributedText = createLine(day: "sat", dayText: "Saturday")
            dayLabels[6].attributedText = createLine(day: "sun", dayText: "Sunday")
        }
    }
    
    class BusinessHour {
        let hours: [Place.Hour]
        let dayHours: [String: String]
        
        init(hours: [Place.Hour]) {
            self.hours = hours
            
            var dayHours = [String: String]()
            for hour in hours.sorted(by: { $0.open > $1.open } ) {
                if let timeText = dayHours[hour.day] {
                    dayHours[hour.day] = timeText + ", " + hour.timeText()
                } else {
                    dayHours[hour.day] = hour.timeText()
                }
            }
            self.dayHours = dayHours
        }
        
        subscript(day: String) -> String {
            get {
                return dayHours[day] ?? "Closed"
            }
        }
        
        func isToday(day: String) -> Bool {
            return day == Place.Hour.Formatter.dayNow().lowercased()
        }
        
        func isOpen() -> Bool {
            return Place.Hour.Formatter.isOpen(hours: hours) ?? false
        }
        
        var today: String {
            return self[Place.Hour.Formatter.dayNow().lowercased()]
        }
    }
}

class PlaceBasicLocationCard: UITableViewCell, PlaceCardView {
    let lineOneLabel = UILabel()
    let lineTwoLabel = UILabel()
    let mapView = MKMapView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        lineOneLabel.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.regular)
        lineOneLabel.numberOfLines = 0
        self.addSubview(lineOneLabel)
        
        lineTwoLabel.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.regular)
        lineTwoLabel.numberOfLines = 1
        self.addSubview(lineTwoLabel)
        
        mapView.isUserInteractionEnabled = false
        mapView.showsUserLocation = true
        self.addSubview(mapView)
        
        lineOneLabel.snp.makeConstraints { make in
            make.top.equalTo(self).inset(topBottom)
            make.left.right.equalTo(self).inset(leftRight)
        }
        
        lineTwoLabel.snp.makeConstraints { make in
            make.top.equalTo(lineOneLabel.snp.bottom)
            make.left.right.equalTo(self).inset(leftRight)
        }
        
        mapView.snp.makeConstraints { make in
            make.top.equalTo(lineTwoLabel.snp.bottom).inset(-16)
            make.left.right.equalTo(self)
            make.bottom.equalTo(self).inset(topBottom)
            
            make.height.equalTo(280)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: PlaceCard) {
        render(lineOne: card)
        render(lineTwo: card)
        render(location: card)
    }
    
    func didTap(card: PlaceCard) {
        var line = [String]()
        
        if let street = card["location"]["street"].string {
            line.append(street)
        }
        
        if let unitNumber = card["location"]["unitNumber"].string {
            if unitNumber.hasPrefix("#") {
                line.append(unitNumber)
            } else {
                line.append("#\(unitNumber)")
            }
        }
        
        if let city = card["location"]["city"].string, let postal = card["location"]["postal"].string {
            line.append("\(city) \(postal)")
        }
        
        func openUrl(address: String) {
            let address = address.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            
            
            // Monster Jobs uses comgooglemap url scheme, those fuckers
            if (UIApplication.shared.canOpenURL(URL(string:"https://www.google.com/maps/")!)) {
                UIApplication.shared.open(URL(string:"https://www.google.com/maps/?daddr=\(address)")!)
            } else if (UIApplication.shared.canOpenURL(URL(string:"http://maps.apple.com/")!)){
                UIApplication.shared.open(URL(string:"http://maps.apple.com/?daddr=\(address)")!)
            }
        }
        
        if (!line.isEmpty) {
            openUrl(address: line.joined(separator: ", "))
        } else if let address = card["location"]["address"].string {
            openUrl(address: address)
        }
    }
    
    private func render(lineOne card: PlaceCard) {
        let location = card["location"]
        var line = [NSAttributedString]()
        
        if let street = location["street"].string {
            line.append(street.set(style: .default {
                $0.font = FontAttribute(font: UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium))
                }
            ))
        }
        
        if let unitNumber = location["unitNumber"].string {
            if unitNumber.hasPrefix("#") {
                line.append(NSAttributedString(string: unitNumber))
            } else {
                line.append(NSAttributedString(string: "#\(unitNumber)"))
            }
        }
        
        if let city = location["city"].string, let postal = location["postal"].string {
            line.append(NSAttributedString(string: "\(city) \(postal)"))
        }
        
        if (!line.isEmpty) {
            let attrString = NSMutableAttributedString(attributedString: line[0])
            for string in line.dropFirst() {
                attrString.append(NSAttributedString(string: ", "))
                attrString.append(string)
            }
            lineOneLabel.attributedText = attrString
        } else if let address = card["location"]["address"].string {
            lineOneLabel.text = address
        }
    }
    
    private func render(lineTwo card: PlaceCard) {
        var line = [String]()
        
        if let latLng = card["location"]["latLng"].string, MunchLocation.isEnabled {
            if let distance = MunchLocation.distance(asMetric: latLng) {
                line.append(distance)
            }
        }
        
        if let nearestTrain = card["location"]["nearestTrain"].string {
            line.append(nearestTrain + " MRT")
        }
        
        lineTwoLabel.text = line.joined(separator: " • ")
    }
    
    private func render(location card: PlaceCard) {
        if let coordinate = CLLocation(latLng: card["location"]["latLng"].stringValue)?.coordinate {
            var region = MKCoordinateRegion()
            region.center.latitude = coordinate.latitude
            region.center.longitude = coordinate.longitude
            region.span.latitudeDelta = 0.004
            region.span.longitudeDelta = 0.004
            mapView.setRegion(region, animated: false)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = card["name"].stringValue
            mapView.addAnnotation(annotation)
        }
    }
    
    static var cardId: String {
        return "basic_Location_15092017"
    }
}
