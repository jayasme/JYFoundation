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
    
    public func interpolate(inRange: [Double], outRange: [Double]) -> Double? {
        
        if (inRange.count != outRange.count) {
            return nil
        }
        
        if (inRange.count == 0) {
            return nil
        }
        
        if (self <= inRange[0]) {
            return outRange[0]
        }
        
        if (self >= inRange[inRange.count - 1]) {
            return outRange[outRange.count - 1]
        }
        
        for i in 0..<inRange.count {
            if (inRange[i] <= self && self <= inRange[i + 1]) {
                let inRangeDiff = inRange[i + 1] - inRange[i]
                let selfDiff = self - inRange[i]
                let t = selfDiff / inRangeDiff
                return outRange[i] * (1 - t) + outRange[i + 1] * t
            }
        }
        
        return nil
    }
}
