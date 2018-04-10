//
//  Munch.swift
//  Munch
//
//  Created by Fuxing Loh on 28/6/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import Kingfisher
import Shimmer

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt32 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        Scanner(string: hexSanitized).scanHexInt32(&rgb)

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }

    static let bgTag = UIColor(hex: "F0F0F7")

    // MARK: Color Palette of Munch App
    static let primary = UIColor.primary500

    class var primary010: UIColor {
        return UIColor(hex: "ffedea")
    }

    class var primary020: UIColor {
        return UIColor(hex: "ffdcd7")
    }

    class var primary030: UIColor {
        return UIColor(hex: "ffcac3")
    }

    class var primary040: UIColor {
        return UIColor(hex: "ffb9b0")
    }

    class var primary050: UIColor {
        return UIColor(hex: "ffa89c")
    }

    class var primary100: UIColor {
        return UIColor(hex: "ff9788")
    }

    class var primary200: UIColor {
        return UIColor(hex: "ff8674")
    }

    class var primary300: UIColor {
        return UIColor(hex: "ff7560")
    }

    class var primary400: UIColor {
        return UIColor(hex: "ff644d")
    }

    static let primary500 = UIColor(hex: "ff5339")

    class var primary600: UIColor {
        return UIColor(hex: "ff4225")
    }

    class var primary700: UIColor {
        return UIColor(hex: "ff3112")
    }

    class var primary800: UIColor {
        return UIColor(hex: "BA3D2A")
    }

    class var primary900: UIColor {
        return UIColor(hex: "A33525")
    }

    class var primary950: UIColor {
        return UIColor(hex: "8C2E20")
    }

    class var secondary: UIColor {
        return .secondary500
    }

    class var secondary050: UIColor {
        return UIColor(hex: "76D5A9")
    }

    class var secondary100: UIColor {
        return UIColor(hex: "5FCE9B")
    }

    class var secondary200: UIColor {
        return UIColor(hex: "48C78C")
    }

    class var secondary300: UIColor {
        return UIColor(hex: "31C07E")
    }

    class var secondary400: UIColor {
        return UIColor(hex: "1AB970")
    }

    class var secondary500: UIColor {
        return UIColor(hex: "04B262")
    }

    class var secondary600: UIColor {
        return UIColor(hex: "04A25A")
    }

    class var secondary700: UIColor {
        return UIColor(hex: "049251")
    }

    class var secondary800: UIColor {
        return UIColor(hex: "038248")
    }

    class var secondary900: UIColor {
        return UIColor(hex: "03723F")
    }

    class var secondary950: UIColor {
        return UIColor(hex: "036236")
    }
}

// Need to deprecate this class, giving me headaches
public class MunchImageView: UIImageView {
    var size: (Int, Int)?
    var images: [(Int, Int, String)]?
    var rendered = false
    var completionHandler: CompletionHandler?

    func render(named: String) {
        self.image = UIImage(named: named)
    }

    /**
     Render SourcedImage to UIImageView
     SourcedImage will contain a ImageMeta to use for rendering
     Shimmer is set to true by default
     */
    func render(sourcedImage: SourcedImage?, completionHandler: CompletionHandler? = nil) {
        render(images: sourcedImage?.images, completionHandler: completionHandler)
    }

    /**
     Render ImageMeta to UIImageView
     Choose the smallest fitting image if available
     Else if the largest images if none fit
     If imageMeta is nil, image will be set to nil too
     Shimmer is set to true by default
     */
    func render(images: [String: String]?, completionHandler: CompletionHandler? = nil) {
        self.images = MunchImageView.imageList(images: images)
        self.completionHandler = completionHandler
        self.rendered = false
        self.tryRender()
    }

    static func fix(url: String) -> URL? {
        // Temporary TODO Remove, add in on server side

        // s3.dualstack.ap-southeast-1.amazonaws.com
        // s3-ap-southeast-1.amazonaws.com
        let url = url.replacingOccurrences(of: "s3-ap-southeast-1.amazonaws.com", with: "s3.dualstack.ap-southeast-1.amazonaws.com")
        return URL(string: url)
    }

    /**
     This try render code might be giving performance issues
     */
    private func tryRender() {
        if rendered {
            return
        }

        if let size = size, let images = self.images {
            if let url = MunchImageView.selectImage(images: images, size: size) {
                kf.setImage(with: MunchImageView.fix(url: url), completionHandler: completionHandler)
            }
            self.rendered = true
        } else {
            kf.setImage(with: nil, completionHandler: completionHandler)
            self.rendered = false
        }
    }

    class func selectImage(images: [(Int, Int, String)], size: (Int, Int)) -> String? {
        let fitting = images.filter {
                    $0.0 >= size.0 && $0.1 >= size.1
                }
                .sorted {
                    $0.0 * $0.1 < $1.0 * $1.1
                }

        if let fit = fitting.get(0) {
            // Found the smallest fitting image
            return fit.2
        } else {
            // No fitting image found, take largest image
            let images = images.sorted {
                $0.0 * $0.1 > $1.0 * $1.1
            }
            if let image = images.get(0) {
                return image.2
            } else {
                return nil
            }
        }
    }

    /**
     Parse [WidthxHeight: Url] into [(Width, Height, Url)]
     */
    class func imageList(images: [String: String]?) -> [(Int, Int, String)]? {
        if let images = images {
            return images.map { key, value -> (Int, Int, String) in
                let widthHeight = key.lowercased().components(separatedBy: "x")
                if (widthHeight.count == 2) {
                    if let width = Int(widthHeight[0]), let height = Int(widthHeight[1]) {
                        return (width, height, value)
                    }
                } else if key == "original" {
                    // Original Image will be the max
                    return (10000, 10000, value)
                }

                // AnyFormat that cannot be parsed will be 0,0
                return (0, 0, value)
            }
        }
        return nil
    }

    class func prefetch(imageList: [[String: String]], size: (Int, Int)) {
        let images: [URL] = imageList.compactMap({
            if let images = MunchImageView.imageList(images: $0) {
                if let image = selectImage(images: images, size: size) {
                    return URL(string: image)
                }
            }
            return nil
        })
        ImagePrefetcher(urls: images).start()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // So that it will only run once
        if self.size == nil {
            self.size = frameSize()
            self.tryRender()
        }
    }

    /**
     Return width and height in pixel
     */
    private func frameSize() -> (Int, Int) {
        let scale = UIScreen.main.scale
        let width = frame.size.width
        let height = frame.size.height
        return (Int(width * scale), Int(height * scale))
    }
}

public class MunchPlist {
    private static let instance = MunchPlist()

    let dictionary: [String: Any]

    init() {
        let path = Bundle.main.path(forResource: "Munch", ofType: "plist")!
        self.dictionary = NSDictionary(contentsOfFile: path) as! [String: Any]
    }

    class func get(key: String) -> Any? {
        return instance.dictionary[key]
    }

    class func get(asString key: String) -> String? {
        return instance.dictionary[key] as? String
    }
}

extension Calendar {
    static func millis(from: Date, to: Date) -> Int {
        return Calendar.current.dateComponents(Set<Calendar.Component>([.nanosecond]), from: from, to: to).nanosecond! / 1000000
    }

    static func micro(from: Date, to: Date) -> Int {
        return Calendar.current.dateComponents(Set<Calendar.Component>([.nanosecond]), from: from, to: to).nanosecond! / 1000
    }
}