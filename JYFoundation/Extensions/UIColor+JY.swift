//
//  UIColor+JY.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/1.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit

extension UIColor {
    
    public static func hexColor(_ hex: UInt32) -> UIColor {
        var r: UInt8 = 0
        var g: UInt8 = 0
        var b: UInt8 = 0
        var a: UInt8 = 0
        if hex < 0x1000000 {
            // rgb
            a = 0xff
        } else {
            // argb
            a = UInt8(hex >> 24)
        }
        r = UInt8(hex >> 16 & 0xff)
        g = UInt8(hex >> 8 & 0xff)
        b = UInt8(hex & 0xff)
        
        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(a) / 255.0)
    }
}

extension CGColor {
    
    public static func hexColor(_ hex: UInt32) -> CGColor {
        return UIColor.hexColor(hex).cgColor
    }
}
