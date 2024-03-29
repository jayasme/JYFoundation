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
}
