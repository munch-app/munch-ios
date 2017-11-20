//
//  PlaceCardBasic.swift
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
import SafariServices
import TTGTagCollectionView

class PlaceBasicImageBannerCard: PlaceCardView {
    let imageGradientView = UIView()
    let imageBannerView = ShimmerImageView()

    override func didLoad(card: PlaceCard) {
        self.addSubview(imageBannerView)
        imageBannerView.snp.makeConstraints { make in
            make.height.equalTo(260).priority(999)
            make.edges.equalTo(self).inset(UIEdgeInsets(top: 0, left: 0, bottom: topBottom, right: 0))
        }

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 64)
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

        imageBannerView.render(images: card["images"][0]["images"])
    }

    override class var cardId: String? {
        return "basic_ImageBanner_20170915"
    }
}

class PlaceBasicNameTagCard: PlaceCardView {
    let nameLabel = UILabel()
    let tagCollection = TTGTextTagCollectionView()

    override func didLoad(card: PlaceCard) {
        self.addSubview(nameLabel)
        self.addSubview(tagCollection)

        nameLabel.text = card["name"].string
        nameLabel.font = UIFont.systemFont(ofSize: 27.0, weight: UIFont.Weight.medium)
        nameLabel.textColor = UIColor.black.withAlphaComponent(0.9)
        nameLabel.numberOfLines = 0
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(self).inset(topBottom)
            make.left.right.equalTo(self).inset(leftRight)
        }

        tagCollection.defaultConfig = DefaultTagConfig()
        tagCollection.horizontalSpacing = 6
        tagCollection.numberOfLines = 0
        tagCollection.alignment = .left
        tagCollection.scrollDirection = .horizontal
        tagCollection.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 3, right: 0)
        tagCollection.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).inset(0)
            make.left.right.equalTo(self).inset(leftRight)
            make.bottom.equalTo(self).inset(topBottom)
        }

        let tags = card["tags"].arrayValue.map({ $0.stringValue.capitalized })
        tagCollection.addTags(tags)
        tagCollection.reload()
    }

    override class var cardId: String? {
        return "basic_NameTag_20170912"
    }

    class DefaultTagConfig: TTGTextTagConfig {
        override init() {
            super.init()

            tagTextFont = UIFont.systemFont(ofSize: 15.0, weight: .regular)
            tagShadowOffset = CGSize.zero
            tagShadowRadius = 0

            tagBorderWidth = 0.5
            tagBorderColor = UIColor.black.withAlphaComponent(0.25)
            tagTextColor = UIColor.black.withAlphaComponent(0.75)
            tagBackgroundColor = UIColor.white

            tagSelectedBorderWidth = 0.5
            tagSelectedBorderColor = UIColor.black.withAlphaComponent(0.25)
            tagSelectedTextColor = UIColor.black.withAlphaComponent(0.75)
            tagSelectedBackgroundColor = UIColor.white

            tagExtraSpace = CGSize(width: 15, height: 8)
        }
    }
}

class PlaceBasicBusinessHourCard: PlaceCardView {
    static let openStyle = Style("open", {
        $0.color = UIColor.secondary
    })
    static let closeStyle = Style("close", {
        $0.color = UIColor.primary
    })

    let grid = UIView()
    let indicator = UIButton()
    let openLabel = UILabel()
    let dayView = DayView()

    var openHeightConstraint: Constraint!
    var dayHeightConstraint: Constraint!

    override func didLoad(card: PlaceCard) {
        self.selectionStyle = .default
        self.addSubview(grid)
        grid.addSubview(indicator)
        grid.addSubview(openLabel)
        grid.addSubview(dayView)

        grid.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)
        }

        indicator.setImage(UIImage(named: "Expand-20"), for: .normal)
        indicator.contentHorizontalAlignment = .right
        indicator.tintColor = .black
        indicator.snp.makeConstraints { make in
            make.right.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)
            make.width.equalTo(25)
        }

        openLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.regular)
        openLabel.numberOfLines = 2
        openLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(grid)
            make.left.equalTo(grid)
            make.right.equalTo(indicator.snp.left)
        }

        let hours = BusinessHour(hours: card["hours"].flatMap({ Place.Hour(json: $0.1) }))
        dayView.render(hours: hours)
        dayView.isHidden = true

        if hours.isOpen() {
            openLabel.attributedText = "Open Now\n".set(style: PlaceBasicBusinessHourCard.openStyle) + hours.today
        } else {
            openLabel.attributedText = "Closed Now\n".set(style: PlaceBasicBusinessHourCard.closeStyle) + hours.today
        }
    }

    override func didTap() {
        dayView.isHidden = !dayView.isHidden
        openLabel.isHidden = !openLabel.isHidden
        indicator.isHidden = !indicator.isHidden

        if (openLabel.isHidden) {
            openLabel.snp.removeConstraints()
            dayView.snp.makeConstraints { (make) in
                make.top.bottom.equalTo(grid)
                make.left.right.equalTo(grid)
                make.height.equalTo(44 * 7).priority(999)
            }
        }

        if (dayView.isHidden) {
            dayView.snp.removeConstraints()
            openLabel.snp.makeConstraints { (make) in
                make.top.bottom.equalTo(grid)
                make.left.equalTo(grid)
                make.right.equalTo(indicator.snp.left)
            }
        }
    }

    override class var cardId: String? {
        return "basic_BusinessHour_20170907"
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
                    make.height.equalTo(44).priority(998)

                    if index == 0 {
                        make.top.equalTo(self)
                    } else {
                        make.top.equalTo(dayLabels[index - 1].snp.bottom)
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
}

class PlaceHeaderAboutCard: PlaceTitleCardView {
    override func didLoad(card: PlaceCard) {
        self.title = "About"
    }

    override class var cardId: String? {
        return "header_About_20171112"
    }
}

class PlaceBasicDescriptionCard: PlaceCardView {
    let descriptionLabel = UILabel()

    override func didLoad(card: PlaceCard) {
        self.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)
        }

        descriptionLabel.text = card["description"].string
        descriptionLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .regular)
        descriptionLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        descriptionLabel.numberOfLines = 0
        if (countLines(label: descriptionLabel) > 2) {
            descriptionLabel.textAlignment = .justified
        }
    }

    func countLines(label: UILabel) -> Int {
        self.layoutIfNeeded()
        let myText = label.text! as NSString

        let rect = CGSize(width: label.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let labelSize = myText.boundingRect(with: rect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: label.font], context: nil)

        return Int(ceil(CGFloat(labelSize.height) / label.font.lineHeight))
    }

    override class var cardId: String? {
        return "basic_Description_20171109"
    }
}

class PlaceBasicPhoneCard: PlaceCardView, SFSafariViewControllerDelegate {
    private let phoneTitleLabel = UILabel()
    private let phoneLabel = UILabel()
    private var phone: String?

    override func didLoad(card: PlaceCard) {
        self.selectionStyle = .default
        self.phone = card["phone"].string
        self.addSubview(phoneTitleLabel)
        self.addSubview(phoneLabel)

        phoneTitleLabel.text = "Phone"
        phoneTitleLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .medium)
        phoneTitleLabel.textColor = .black
        phoneTitleLabel.textAlignment = .left
        phoneTitleLabel.numberOfLines = 1
        phoneTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)
            make.width.equalTo(70)
        }

        phoneLabel.attributedText = phone?.set(style: .default { make in
//            make.underline = UnderlineAttribute(color: UIColor.black.withAlphaComponent(0.4), style: NSUnderlineStyle.styleSingle)
            make.font = FontAttribute(font: UIFont.systemFont(ofSize: 15.0, weight: .regular))
            make.color = UIColor.black.withAlphaComponent(0.8)
        })
        phoneLabel.textAlignment = .right
        phoneLabel.numberOfLines = 1
        phoneLabel.snp.makeConstraints { make in
            make.right.equalTo(self).inset(leftRight)
            make.left.equalTo(phoneTitleLabel.snp.right).inset(-10)
            make.top.bottom.equalTo(self).inset(topBottom)
        }
    }

    override func didTap() {
        if let phone = self.phone {
            if let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }

    override class var cardId: String? {
        return "basic_Phone_20171117"
    }
}

class PlaceBasicWebsiteCard: PlaceCardView, SFSafariViewControllerDelegate {
    private let websiteTitleLabel = UILabel()
    private let websiteLabel = UILabel()
    private var websiteUrl: String?

    override func didLoad(card: PlaceCard) {
        self.selectionStyle = .default
        self.websiteUrl = card["website"].string
        self.addSubview(websiteTitleLabel)
        self.addSubview(websiteLabel)

        websiteTitleLabel.text = "Website"
        websiteTitleLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .medium)
        websiteTitleLabel.textColor = .black
        websiteTitleLabel.textAlignment = .left
        websiteTitleLabel.numberOfLines = 1
        websiteTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)
            make.width.equalTo(70)
        }

        websiteLabel.attributedText = websiteUrl?.set(style: .default { make in
//            make.underline = UnderlineAttribute(color: UIColor.black.withAlphaComponent(0.4), style: NSUnderlineStyle.styleSingle)
            make.font = FontAttribute(font: UIFont.systemFont(ofSize: 15.0, weight: .regular))
            make.color = UIColor.black.withAlphaComponent(0.8)
        })
        websiteLabel.textAlignment = .right
        websiteLabel.numberOfLines = 1
        websiteLabel.snp.makeConstraints { make in
            make.right.equalTo(self).inset(leftRight)
            make.left.equalTo(websiteTitleLabel.snp.right).inset(-10)
            make.top.bottom.equalTo(self).inset(topBottom)
        }
    }

    override func didTap() {
        if let websiteUrl = websiteUrl, let url = URL.init(string: websiteUrl) {
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            controller.present(safari, animated: true, completion: nil)
        }
    }

    override class var cardId: String? {
        return "basic_Website_20171109"
    }
}

class PlaceBasicAddressCard: PlaceCardView {
    private let addressLabel = AddressLabel()
    private var address: String?

    override func didLoad(card: PlaceCard) {
        self.addSubview(addressLabel)
        self.address = card["address"].string

        addressLabel.render(card: card)
        addressLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(self).inset(topBottom)
            make.left.right.equalTo(self).inset(leftRight)
        }
    }

    override func didTap() {
        if let address = address?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            // Monster Jobs uses comgooglemap url scheme, those fuckers
            if (UIApplication.shared.canOpenURL(URL(string: "https://www.google.com/maps/")!)) {
                UIApplication.shared.open(URL(string: "https://www.google.com/maps/?daddr=\(address)")!)
            } else if (UIApplication.shared.canOpenURL(URL(string: "http://maps.apple.com/")!)) {
                UIApplication.shared.open(URL(string: "http://maps.apple.com/?daddr=\(address)")!)
            }
        }
    }

    override class var cardId: String? {
        return "basic_Address_20170924"
    }
}

fileprivate class AddressLabel: UIView {
    let lineOneLabel = UILabel()
    let lineTwoLabel = UILabel()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        lineOneLabel.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.regular)
        lineOneLabel.numberOfLines = 0
        self.addSubview(lineOneLabel)

        lineTwoLabel.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.regular)
        lineTwoLabel.numberOfLines = 1
        self.addSubview(lineTwoLabel)

        lineOneLabel.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.left.right.equalTo(self)
        }

        lineTwoLabel.snp.makeConstraints { make in
            make.top.equalTo(lineOneLabel.snp.bottom)
            make.left.right.equalTo(self)
            make.bottom.equalTo(self)
        }
    }

    func render(card: PlaceCard) {
        render(lineOne: card)
        render(lineTwo: card)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func render(lineOne card: PlaceCard) {
        var line = [NSAttributedString]()

        if let street = card["street"].string {
            line.append(street.set(style: .default {
                $0.font = FontAttribute(font: UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium))
            }
            ))
        }

        if let unitNumber = card["unitNumber"].string {
            if unitNumber.hasPrefix("#") {
                line.append(NSAttributedString(string: unitNumber))
            } else {
                line.append(NSAttributedString(string: "#\(unitNumber)"))
            }
        }

        if let city = card["city"].string, let postal = card["postal"].string {
            line.append(NSAttributedString(string: "\(city) \(postal)"))
        }

        if (!line.isEmpty) {
            let attrString = NSMutableAttributedString(attributedString: line[0])
            for string in line.dropFirst() {
                attrString.append(NSAttributedString(string: ", "))
                attrString.append(string)
            }
            lineOneLabel.attributedText = attrString
        } else if let address = card["address"].string {
            lineOneLabel.text = address
        }
    }

    private func render(lineTwo card: PlaceCard) {
        var line = [String]()

        if let latLng = card["latLng"].string, MunchLocation.isEnabled {
            if let distance = MunchLocation.distance(asMetric: latLng) {
                line.append(distance)
            }
        }

        if let nearestTrain = card["nearestTrain"].string {
            line.append(nearestTrain + " MRT")
        }

        lineTwoLabel.text = line.joined(separator: " • ")
    }
}

class PlaceHeaderLocationCard: PlaceTitleCardView {
    override func didLoad(card: PlaceCard) {
        self.title = "Location"
    }

    override class var cardId: String? {
        return "header_Location_20171112"
    }
}

class PlaceBasicLocationCard: PlaceCardView {
    private let addressLabel = AddressLabel()
    private let mapView = MKMapView()
    private var address: String?

    override func didLoad(card: PlaceCard) {
        self.addSubview(addressLabel)
        self.addSubview(mapView)
        self.address = card["address"].string

        addressLabel.render(card: card)
        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(self).inset(topBottom)
            make.left.right.equalTo(self).inset(leftRight)
        }

        mapView.isUserInteractionEnabled = false
        mapView.showsUserLocation = false
        mapView.snp.makeConstraints { make in
            make.top.equalTo(addressLabel.snp.bottom).inset(-24)
            make.bottom.equalTo(self)
            make.left.right.equalTo(self)
            make.height.equalTo(230)
        }

        render(location: card)
    }

    override func didTap() {
        if let address = address?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            // Monster Jobs uses comgooglemap url scheme, those fuckers
            if (UIApplication.shared.canOpenURL(URL(string: "https://www.google.com/maps/")!)) {
                UIApplication.shared.open(URL(string: "https://www.google.com/maps/?daddr=\(address)")!)
            } else if (UIApplication.shared.canOpenURL(URL(string: "http://maps.apple.com/")!)) {
                UIApplication.shared.open(URL(string: "http://maps.apple.com/?daddr=\(address)")!)
            }
        }
    }

    private func render(location card: PlaceCard) {
        if let coordinate = CLLocation(latLng: card["latLng"].stringValue)?.coordinate {
            var region = MKCoordinateRegion()
            region.center.latitude = coordinate.latitude
            region.center.longitude = coordinate.longitude
            region.span.latitudeDelta = 0.004
            region.span.longitudeDelta = 0.004
            mapView.setRegion(region, animated: false)

            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = card["placeName"].stringValue
            mapView.addAnnotation(annotation)
        }
    }

    override class var cardId: String? {
        return "basic_Location_20171112"
    }
}
