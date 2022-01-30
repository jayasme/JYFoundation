//
//  Double+JY.swift
//  JYFoundation
//
//  Created by 荣超 on 2022/1/29.
//  Copyright © 2022 jayasme. All rights reserved.
//

import UIKit

extension Double {
    
    public static func random(max: Double) -> Double {
        return Double(drand48() * Double(max))
    }
    
    public static func random(min: Double, max: Double) -> Double {
        return drand48() * Double(max - min) + min
    }
    
    // operator overrides
    
    public static func + (left: Double, right: Int) -> Double {
        return left + Double(right)
    }
    
    public static func + (left: Double, right: CGFloat) -> Double {
        return left + Double(right)
    }
    
    public static func + (left: Double, right: String) -> String {
        return String(format: "%lf", left) + right
    }
    
    public static func - (left: Double, right: Int) -> Double {
        return left - Double(right)
    }
    
    public static func - (left: Double, right: CGFloat) -> Double {
        return left - Double(right)
    }
    
    public static func * (left: Double, right: Int) -> Double {
        return left * Double(right)
    }
    
    public static func * (left: Double, right: CGFloat) -> Double {
        return left * Double(right)
    }

    public static func / (left: Double, right: Int) -> Double {
        return left / Double(right)
    }
    
    public static func / (left: Double, right: CGFloat) -> Double {
        return left / Double(right)
    }

    public static func += (left: inout Double, right: Int) {
        left += Double(right)
    }
    
    public static func += (left: inout Double, right: CGFloat) {
        left += Double(right)
    }
    
    public static func -= (left: inout Double, right: Int) {
        left -= Double(right)
    }
    
    public static func -= (left: inout Double, right: CGFloat) {
        left -= Double(right)
    }
    
    
    public static func == (left: Double, right: Int) -> Bool {
        return left == Double(right)
    }
    
    public static func == (left: Double, right: CGFloat) -> Bool {
        return left == Double(right)
    }
    
    public static func > (left: Double, right: Int) -> Bool {
        return left > Double(right)
    }
    
    public static func > (left: Double, right: CGFloat) -> Bool {
        return left > Double(right)
    }
    
    public static func < (left: Double, right: Int) -> Bool {
        return left < Double(right)
    }
    
    public static func < (left: Double, right: CGFloat) -> Bool {
        return left < Double(right)
    }
    
    public static func >= (left: Double, right: Int) -> Bool {
        return left >= Double(right)
    }
    
    public static func >= (left: Double, right: CGFloat) -> Bool {
        return left >= Double(right)
    }
    
    public static func <= (left: Double, right: Int) -> Bool {
        return left <= Double(right)
    }
    
    public static func <= (left: Double, right: CGFloat) -> Bool {
        return left <= Double(right)
    }
}
