//
//  Double+JY.swift
//  JYFoundation
//
//  Created by 荣超 on 2022/1/29.
//  Copyright © 2022 jayasme. All rights reserved.
//

import UIKit

extension Double {
    
    public static func random(range: ClosedRange<Double>) -> Double {
        return drand48() * Double(range.upperBound - range.lowerBound) + range.lowerBound
    }
    
    public func zeroToNil() -> Double? {
        return self.isZero ? nil : self
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
