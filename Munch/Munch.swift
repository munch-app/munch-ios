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
    static let bgRed = UIColor(hex: "ffddea")

    // MARK: Color Palette of Munch App
    static let primary = UIColor.primary500
    static let primary010 = UIColor(hex: "ffedea")
    static let primary020 = UIColor(hex: "ffdcd7")
    static let primary030 = UIColor(hex: "ffcac3")
    static let primary040 = UIColor(hex: "ffb9b0")
    static let primary050 = UIColor(hex: "ffa89c")
    static let primary100 = UIColor(hex: "ff9788")
    static let primary200 = UIColor(hex: "ff8674")
    static let primary300 = UIColor(hex: "ff7560")
    static let primary400 = UIColor(hex: "ff644d")
    static let primary500 = UIColor(hex: "ff5339")
    static let primary600 = UIColor(hex: "ff4225")
    static let primary700 = UIColor(hex: "ff3112")
    static let primary800 = UIColor(hex: "BA3D2A")
    static let primary900 = UIColor(hex: "A33525")
    static let primary950 = UIColor(hex: "8C2E20")

    static let secondary = UIColor.secondary500
    static let secondary050 = UIColor(hex: "76D5A9")
    static let secondary100 = UIColor(hex: "5FCE9B")
    static let secondary200 = UIColor(hex: "48C78C")
    static let secondary300 = UIColor(hex: "31C07E")
    static let secondary400 = UIColor(hex: "1AB970")
    static let secondary500 = UIColor(hex: "04B262")
    static let secondary600 = UIColor(hex: "04A25A")
    static let secondary700 = UIColor(hex: "049251")
    static let secondary800 = UIColor(hex: "038248")
    static let secondary900 = UIColor(hex: "03723F")
    static let secondary950 = UIColor(hex: "036236")
}

// Need to deprecate this class, giving me headaches
public class MunchImageView: UIImageView {
    var size: CGSize?
    var images: [(CGSize, String)]?
    var rendered = false
    var completionHandler: CompletionHandler?
    let overlay = UIView()

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(overlay)
        overlay.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
//        let url = url.replacingOccurrences(of: "s3-ap-southeast-1.amazonaws.com", with: "s3.dualstack.ap-southeast-1.amazonaws.com")
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

    class func selectImage(images: [(CGSize, String)], size: CGSize) -> String? {
        let fitting = images.filter {
                    $0.0.width >= size.width && $0.0.height >= size.height
                }
                .sorted {
                    $0.0.width * $0.0.height < $1.0.width * $1.0.height
                }

        if let fit = fitting.get(0) {
            // Found the smallest fitting image
            return fit.1
        } else {
            // No fitting image found, take largest image
            let images = images.sorted {
                $0.0.width * $0.0.height > $1.0.width * $1.0.height
            }
            if let image = images.get(0) {
                return image.1
            } else {
                return nil
            }
        }
    }

    /**
     Parse [WidthxHeight: Url] into [(Width, Height, Url)]
     */
    class func imageList(images: [String: String]?) -> [(CGSize, String)]? {
        if let images = images {
            return images.map { key, value -> (CGSize, String) in
                let widthHeight = key.lowercased().components(separatedBy: "x")
                if (widthHeight.count == 2) {
                    if let width = Int(widthHeight[0]), let height = Int(widthHeight[1]) {
                        return (CGSize(width: width, height: height), value)
                    }
                } else if key == "original" {
                    // Original Image will be the max
                    return (CGSize(width: 10000, height: 10000), value)
                }

                // AnyFormat that cannot be parsed will be 0,0
                return (CGSize(width: 0, height: 0), value)
            }
        }
        return nil
    }

    class func prefetch(imageList: [[String: String]], size: CGSize) {
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
    private func frameSize() -> CGSize {
        let scale = UIScreen.main.scale
        let width = frame.size.width
        let height = frame.size.height
        return CGSize(width: width * scale, height: height * scale)
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

extension String {
    var urlEscaped: String {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }

    var utf8Encoded: Data {
        return data(using: .utf8)!
    }
}