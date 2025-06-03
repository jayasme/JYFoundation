//
//  CGFloat+JY.swift
//  JYFoundation
//
//  Created by 荣超 on 2022/1/29.
//  Copyright © 2022 jayasme. All rights reserved.
//

import UIKit

extension CGFloat {
    
    public init?(_ text: any StringProtocol) {
        guard let float = Float(text) else {
            return nil
        }
        self = CGFloat(float)
    }
    
    public static func random(range: ClosedRange<CGFloat>) -> CGFloat {
        return CGFloat(drand48() * Double(range.upperBound - range.lowerBound)) + range.lowerBound
    }
    
    public func zeroToNil() -> CGFloat? {
        return self.isZero ? nil : self
    }
    
    // operator overrides
    
    public static func + (left: CGFloat, right: Int) -> CGFloat {
        return left + CGFloat(right)
    }
    
    public static func + (left: CGFloat, right: Double) -> Double {
        return Double(left) + right
    }
    
    public static func + (left: CGFloat, right: String) -> String {
        return String(format: "%g", left) + right
    }
    
    public static func - (left: CGFloat, right: Int) -> CGFloat {
        return left - CGFloat(right)
    }
    
    public static func - (left: CGFloat, right: Double) -> Double {
        return Double(left) - right
    }
    
    public static func * (left: CGFloat, right: Int) -> CGFloat {
        return left * CGFloat(right)
    }
    
    public static func * (left: CGFloat, right: Double) -> Double {
        return Double(left) * right
    }

    public static func / (left: CGFloat, right: Int) -> CGFloat {
        return left / CGFloat(right)
    }
    
    public static func / (left: CGFloat, right: Double) -> Double {
        return Double(left) / right
    }

    public static func += (left: inout CGFloat, right: Int) {
        left += CGFloat(right)
    }
    
    public static func += (left: inout CGFloat, right: Double) {
        left += CGFloat(right)
    }
    
    public static func -= (left: inout CGFloat, right: Int) {
        left -= CGFloat(right)
    }
    
    public static func -= (left: inout CGFloat, right: Double) {
        left -= CGFloat(right)
    }
    
    
    public static func == (left: CGFloat, right: Int) -> Bool {
        return left == CGFloat(right)
    }
    
    public static func == (left: CGFloat, right: Double) -> Bool {
        return Double(left) == right
    }
    
    public static func > (left: CGFloat, right: Int) -> Bool {
        return left > CGFloat(right)
    }
    
    public static func > (left: CGFloat, right: Double) -> Bool {
        return Double(left) > right
    }
    
    public static func < (left: CGFloat, right: Int) -> Bool {
        return left < CGFloat(right)
    }
    
    public static func < (left: CGFloat, right: Double) -> Bool {
        return Double(left) < right
    }
    
    public static func >= (left: CGFloat, right: Int) -> Bool {
        return left >= CGFloat(right)
    }
    
    public static func >= (left: CGFloat, right: Double) -> Bool {
        return Double(left) >= right
    }
    
    public static func <= (left: CGFloat, right: Int) -> Bool {
        return left <= CGFloat(right)
    }
    
    public static func <= (left: CGFloat, right: Double) -> Bool {
        return Double(left) <= right
    }
    
    public func interpolate(inRange: [CGFloat], outRange: [CGFloat]) -> CGFloat? {
        
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
