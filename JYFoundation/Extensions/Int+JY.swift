//
//  Int+JY.swift
//  JYFoundation
//
//  Created by 荣超 on 2022/1/29.
//  Copyright © 2022 jayasme. All rights reserved.
//

import UIKit

extension Int {
    
    public static func random(range: ClosedRange<Int>) -> Int {
        srand48(Int(Date.now.timeIntervalSince1970))
        return Int(drand48() * Double(range.upperBound - range.lowerBound + 1)) + range.lowerBound
    }
    
    public static func random(range: Range<Int>) -> Int {
        srand48(Int(Date.now.timeIntervalSince1970))
        return Int(drand48() * Double(range.upperBound - range.lowerBound)) + range.lowerBound
    }
    
    public func zeroToNil() -> Int? {
        return self == 0 ? nil : self
    }
    
    // operator overrides
    
    public static func + (left: Int, right: CGFloat) -> CGFloat {
        return CGFloat(left) + right
    }
    
    public static func + (left: Int, right: Double) -> Double {
        return Double(left) + right
    }
    
    public static func + (left: Int, right: String) -> String {
        return String(left) + right
    }
    
    public static func - (left: Int, right: CGFloat) -> CGFloat {
        return CGFloat(left) - right
    }
    
    public static func - (left: Int, right: Double) -> Double {
        return Double(left) - right
    }
    
    public static func * (left: Int, right: CGFloat) -> CGFloat {
        return CGFloat(left) * right
    }
    
    public static func * (left: Int, right: Double) -> Double {
        return Double(left) * right
    }

    public static func / (left: Int, right: CGFloat) -> CGFloat {
        return CGFloat(left) / right
    }
    
    public static func / (left: Int, right: Double) -> Double {
        return Double(left) / right
    }

    public static func += (left: inout Int, right: CGFloat) {
        left += Int(right)
    }
    
    public static func += (left: inout Int, right: Double) {
        left += Int(right)
    }
    
    public static func -= (left: inout Int, right: CGFloat) {
        left -= Int(right)
    }
    
    public static func -= (left: inout Int, right: Double) {
        left -= Int(right)
    }
    
    
    public static func == (left: Int, right: CGFloat) -> Bool {
        return CGFloat(left) == right
    }
    
    public static func == (left: Int, right: Double) -> Bool {
        return Double(left) == right
    }
    
    public static func > (left: Int, right: CGFloat) -> Bool {
        return CGFloat(left) > right
    }
    
    public static func > (left: Int, right: Double) -> Bool {
        return Double(left) > right
    }
    
    public static func < (left: Int, right: CGFloat) -> Bool {
        return CGFloat(left) < right
    }
    
    public static func < (left: Int, right: Double) -> Bool {
        return Double(left) < right
    }
    
    public static func >= (left: Int, right: CGFloat) -> Bool {
        return CGFloat(left) >= right
    }
    
    public static func >= (left: Int, right: Double) -> Bool {
        return Double(left) >= right
    }
    
    public static func <= (left: Int, right: CGFloat) -> Bool {
        return CGFloat(left) <= right
    }
    
    public static func <= (left: Int, right: Double) -> Bool {
        return Double(left) <= right
    }
}
