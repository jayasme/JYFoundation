//
//  UIColor+JY.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/1.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit

extension UIColor {
    
    public convenience init(hex: UInt32) {
        var a: UInt8 = 0
        if hex < 0x1000000 {
            // rgb
            a = 0xff
        } else {
            // argb
            a = UInt8(hex >> 24)
        }
        let r = UInt8(hex >> 16 & 0xff)
        let g = UInt8(hex >> 8 & 0xff)
        let b = UInt8(hex & 0xff)
        
        self.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(a) / 255.0)
    }
    
    public convenience init?(hexString: String) {
        guard hexString.starts(with: "#") else {
            return nil
        }
        
        guard let hex = UInt32(hexString.dropFirst(), radix: 16) else {
            return nil
        }
        
        self.init(hex: hex)
    }
    
    public var hex: UInt32 {
        var rf: CGFloat = 0
        var gf: CGFloat = 0
        var bf: CGFloat = 0
        var af: CGFloat = 0
        
        self.getRed(&rf, green: &gf, blue: &bf, alpha: &af)
        var hex: UInt32 = 0
        hex = hex << 8 | UInt32(af * 255)
        hex = hex << 8 | UInt32(rf * 255)
        hex = hex << 8 | UInt32(gf * 255)
        hex = hex << 8 | UInt32(bf * 255)
        
        return hex
    }
    
    public var hexString: String {
        return String(format: "#%02X", self.hex)
    }
}
