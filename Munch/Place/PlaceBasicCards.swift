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
    let imageBannerView = UIImageView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        imageBannerView.contentMode = .scaleAspectFill
        imageBannerView.clipsToBounds = true
        self.addSubview(imageBannerView)
        
        imageBannerView.snp.makeConstraints { make in
            make.height.equalTo(260)
            make.edges.equalTo(self).inset(UIEdgeInsets(top: 0, left: 0, bottom: topBottom, right: 0))
        }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.width, height: 64)
        gradientLayer.colors = [UIColor.black.withAlphaComponent(0.5).cgColor, UIColor.clear.cgColor]
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
    
    static var id: String {
        return "basic_ImageBanner_11092017"
    }
}

class PlaceBasicNameTagCard: UITableViewCell, PlaceCardView {
    let nameLabel = UILabel()
    // TODO Tag Label
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        nameLabel.font = UIFont.systemFont(ofSize: 27.0, weight: UIFontWeightMedium)
        nameLabel.numberOfLines = 0
        self.addSubview(nameLabel)
        
        nameLabel.snp.makeConstraints { make in
            make.edges.equalTo(self).inset(UIEdgeInsets(topBottom: topBottom, leftRight: leftRight))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: PlaceCard) {
        self.nameLabel.text = card["name"].stringValue
    }
    
    static var id: String {
        return "basic_NameTag_12092017"
    }
}

class PlaceBasicBusinessHourCard: UITableViewCell, PlaceCardView {
    let openingLabel = UILabel()
    let hoursLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        openingLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightRegular)
        openingLabel.numberOfLines = 1
        self.addSubview(openingLabel)
        
        hoursLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightRegular)
        hoursLabel.numberOfLines = 0
        self.addSubview(hoursLabel)
        
        openingLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            
            make.top.equalTo(self)
            make.height.equalTo(20)
        }
        
        hoursLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            
            make.top.equalTo(openingLabel.snp.bottom)
            make.bottom.equalTo(self).inset(topBottom)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: PlaceCard) {
        let hours = card["hours"].flatMap { Place.Hour(json: $0.1) }
            .sorted { $0.0.open > $0.1.open }
        
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
                    $0.font = FontAttribute(font: UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightSemibold))
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
    
    static var id: String {
        return "basic_BusinessHour_07092017"
    }
}

class PlaceBasicLocationCard: UITableViewCell, PlaceCardView {
    let lineOneLabel = UILabel()
    let lineTwoLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        lineOneLabel.font = UIFont.systemFont(ofSize: 15.0, weight: UIFontWeightRegular)
        lineOneLabel.numberOfLines = 0
        self.addSubview(lineOneLabel)
        
        lineTwoLabel.font = UIFont.systemFont(ofSize: 15.0, weight: UIFontWeightRegular)
        lineTwoLabel.numberOfLines = 1
        self.addSubview(lineTwoLabel)
        
        lineOneLabel.snp.makeConstraints { make in
            make.height.equalTo(lineTwoLabel)
            make.top.equalTo(self).inset(topBottom)
            make.bottom.equalTo(lineTwoLabel.snp.top)
            
            make.left.right.equalTo(self).inset(leftRight)
        }
        
        lineTwoLabel.snp.makeConstraints { make in
            make.height.equalTo(lineOneLabel)
            make.top.equalTo(lineOneLabel.snp.bottom)
            make.bottom.equalTo(self).inset(topBottom)
            
            make.left.right.equalTo(self).inset(leftRight)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: PlaceCard) {
        render(lineOne: card)
        render(lineTwo: card)
    }
    
    private func render(lineOne card: PlaceCard) {
        var line = [String]()
        
        if let latLng = card["location"]["latLng"].string, MunchLocation.enabled {
            if let distance = MunchLocation.distance(asMetric: latLng) {
                line.append(distance)
            }
        }
        
        if let nearestTrain = card["location"]["nearestTrain"].string {
            line.append(nearestTrain + " MRT")
        }
        
        lineTwoLabel.text = line.joined(separator: " • ")
    }
    
    private func render(lineTwo card: PlaceCard) {
        let location = card["location"]
        var line = [String]()
        
        if let street = location["street"].string {
            line.append(street)
        }
        
        if let unitNumber = location["unitNumber"].string {
            line.append(unitNumber)
        }
        
        if let city = location["city"].string, let postal = location["postal"].string {
            line.append("\(city) \(postal)")
        }
        
        if (line.isEmpty) {
            let address = card["location"]["address"].string
            lineOneLabel.text = address
        } else {
            lineOneLabel.text = line.joined(separator: ", ")
        }
    }
    
    static var id: String {
        return "basic_Location_12092017"
    }
}
