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
    let openingLabel = UILabel()
    let hoursLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        openingLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.regular)
        openingLabel.numberOfLines = 1
        self.addSubview(openingLabel)
        
        hoursLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.regular)
        hoursLabel.numberOfLines = 0
        self.addSubview(hoursLabel)
        
        openingLabel.snp.makeConstraints { make in
            make.top.equalTo(self).inset(topBottom)
            make.left.right.equalTo(self).inset(leftRight)
            make.height.equalTo(20)
        }
        
        hoursLabel.snp.makeConstraints { make in
            make.top.equalTo(openingLabel.snp.bottom)
            make.left.right.equalTo(self).inset(leftRight)
            make.bottom.equalTo(self).inset(topBottom)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: PlaceCard) {
        let hours = card["hours"].flatMap { Place.Hour(json: $0.1) }
            .sorted(by: { $0.open > $1.open } )
        
        if Place.Hour.Formatter.isOpen(hours: hours) ?? false {
            openingLabel.attributedText = "Open Now:".set(style: Style.default {
                $0.color = UIColor.secondary
            })
        } else {
            openingLabel.attributedText = "Closed Now:".set(style: Style.default {
                $0.color = UIColor.primary
            })
        }
        
        var dayHours = [String: String]()
        for hour in hours {
            if let timeText = dayHours[hour.day] {
                dayHours[hour.day] = timeText + ", " + hour.timeText()
            } else {
                dayHours[hour.day] = hour.timeText()
            }
        }
        
        let dayNow = Place.Hour.Formatter.dayNow().lowercased()
        
        func createLine(day: String, append: String = "\n", dayText: String? = nil) -> NSAttributedString {
            let text: String
            
            if let time = dayHours[day] {
                text = "\(dayText ?? day.uppercased()): \(time) \(append)"
            } else {
                text = "\(dayText ?? day.uppercased()): Closed \(append)"
            }
            
            
            if (day == dayNow) {
                return text.set(style: Style.default {
                    $0.font = FontAttribute(font: UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.semibold))
                })
            }
            
            return NSAttributedString(string: text)
        }
        
        let hourText = NSMutableAttributedString()
        hourText.append(createLine(day: "mon"))
        hourText.append(createLine(day: "tue"))
        hourText.append(createLine(day: "wed"))
        hourText.append(createLine(day: "thu"))
        hourText.append(createLine(day: "fri"))
        hourText.append(createLine(day: "sat"))
        hourText.append(createLine(day: "sun"))
        hourText.append(createLine(day: "ph", dayText: "PH"))
        hourText.append(createLine(day: "evePh", append: "", dayText: "Eve of PH"))
        
        hoursLabel.attributedText = hourText
    }
    
    static var cardId: String {
        return "basic_BusinessHour_07092017"
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
    
    private func render(lineOne card: PlaceCard) {
        let location = card["location"]
        var line = [NSAttributedString]()
        
        if let street = location["street"].string {
            line.append(street.set(style: .default {
                $0.font = FontAttribute(font: UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium))
            }))
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
        
        if (line.isEmpty) {
            lineOneLabel.text = card["location"]["address"].string
        } else {
            let attrString = NSMutableAttributedString(attributedString: line[0])
            for string in line.dropFirst() {
                attrString.append(NSAttributedString(string: ", "))
                attrString.append(string)
            }
            lineOneLabel.attributedText = attrString
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
