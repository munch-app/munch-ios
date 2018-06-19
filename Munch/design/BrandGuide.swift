//
// Created by Fuxing Loh on 18/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import Toast_Swift

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

let DefaultToastStyle: Toast_Swift.ToastStyle = {
    var style = ToastStyle()
    style.backgroundColor = UIColor.bgTag
    style.cornerRadius = 5
    style.imageSize = CGSize(width: 20, height: 20)
    style.fadeDuration = 6.0
    style.messageColor = UIColor.black.withAlphaComponent(0.85)
    style.messageFont = UIFont.systemFont(ofSize: 15, weight: .regular)
    style.messageNumberOfLines = 2
    style.messageAlignment = .left

    return style
}()