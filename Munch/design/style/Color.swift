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
}

extension UIColor {
    static let void = UIColor(hex: "F0F0F0")

    static let ba10 = UIColor.black.withAlphaComponent(0.10)
    static let ba15 = UIColor.black.withAlphaComponent(0.15)
    static let ba20 = UIColor.black.withAlphaComponent(0.20)
    static let ba40 = UIColor.black.withAlphaComponent(0.40)
    static let ba50 = UIColor.black.withAlphaComponent(0.50)
    static let ba60 = UIColor.black.withAlphaComponent(0.60)
    static let ba75 = UIColor.black.withAlphaComponent(0.75)
    static let ba80 = UIColor.black.withAlphaComponent(0.80)
    static let ba85 = UIColor.black.withAlphaComponent(0.85)

    static let primary050 = UIColor(hex: "FACFC4")
    static let primary100 = UIColor(hex: "F7AF9D")
    static let primary200 = UIColor(hex: "F59982")
    static let primary300 = UIColor(hex: "F4866A")
    static let primary400 = UIColor(hex: "F27253")
    static let primary500 = UIColor(hex: "F05F3B")
    static let primary600 = UIColor(hex: "EE4C23")
    static let primary700 = UIColor(hex: "E73C12")
    static let primary800 = UIColor(hex: "D0350E")
    static let primary900 = UIColor(hex: "AC2D0E")

    static let secondary050 = UIColor(hex: "B8CBD3")
    static let secondary100 = UIColor(hex: "8CB2C0")
    static let secondary200 = UIColor(hex: "6CA0B5")
    static let secondary300 = UIColor(hex: "478DA6")
    static let secondary400 = UIColor(hex: "227190")
    static let secondary500 = UIColor(hex: "0A6284")
    static let secondary600 = UIColor(hex: "095876")
    static let secondary700 = UIColor(hex: "084E69")
    static let secondary800 = UIColor(hex: "07445C")
    static let secondary900 = UIColor(hex: "063A4F")

    static let keppel500 = UIColor(hex: "429F9B")
    static let falu500 = UIColor(hex: "89201A")

    static let juan = UIColor(hex: "595353")
    static let celeste = UIColor(hex: "CFD1CD")
    static let athens = UIColor(hex: "F4F5F7")

    static let peach100 = UIColor(hex: "faf0f0")
    static let peach200 = UIColor(hex: "f0e0e0")

    static let saltpan100 = UIColor(hex: "F1F9F1")
    static let saltpan200 = UIColor(hex: "E0F0E0")

    static let whisper050 = UIColor(hex: "f9f9fd")
    static let whisper100 = UIColor(hex: "F0F0F8")
    static let whisper200 = UIColor(hex: "dfdff0")

    static let open = UIColor(hex: "20A700")
    static let success = UIColor(hex: "20A700")

    static let close = UIColor(hex: "EC152C")
    static let error = UIColor(hex: "EC152C")
}