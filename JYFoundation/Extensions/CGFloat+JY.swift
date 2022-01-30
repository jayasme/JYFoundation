//
//  CGFloat+JY.swift
//  JYFoundation
//
//  Created by 荣超 on 2022/1/29.
//  Copyright © 2022 jayasme. All rights reserved.
//

import UIKit

extension CGFloat {
    
    public static func random(max: CGFloat) -> CGFloat {
        return CGFloat(drand48() * Double(max))
    }
    
    public static func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return CGFloat(drand48() * Double(max - min)) + min
    }
    
    // operator overrides
    
    public static func + (left: CGFloat, right: Int) -> CGFloat {
        return left + CGFloat(right)
    }
    
    public static func + (left: CGFloat, right: Double) -> Double {
        return Double(left) + right
    }
    
    public static func + (left: CGFloat, right: String) -> String {
        return String(format: "%f", left) + right
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
