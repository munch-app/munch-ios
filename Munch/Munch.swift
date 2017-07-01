//
//  Munch.swift
//  Munch
//
//  Created by Fuxing Loh on 28/6/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt32 = 0
        
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0
        
        let length = hexSanitized.characters.count
        
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
    
    // MARK: Color Palette of Munch App
    class var primary: UIColor {
        return .primary500
    }
    
    class var primary050: UIColor {
        return UIColor(hex: "FFA193")
    }
    
    class var primary100: UIColor {
        return UIColor(hex: "FF9181")
    }
    
    class var primary200: UIColor {
        return UIColor(hex: "FF816F")
    }
    
    class var primary300: UIColor {
        return UIColor(hex: "FF725D")
    }
    
    class var primary400: UIColor {
        return UIColor(hex: "FF624B")
    }
    
    class var primary500: UIColor {
        return UIColor(hex: "FF5339")
    }
    
    class var primary600: UIColor {
        return UIColor(hex: "E84C34")
    }
    
    class var primary700: UIColor {
        return UIColor(hex: "D1442F")
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
