//
//  CGPoint+JY.swift
//  JYFoundation
//
//  Created by 荣超 on 2022/3/31.
//  Copyright © 2022 jayasme. All rights reserved.
//

import Foundation
import UIKit

extension CGPoint {
    
    public static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    public static func - (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
    
    public static func == (left: CGPoint, right: CGPoint) -> Bool {
        return left.x == right.x && left.y == right.y
    }
    
    public static func += (left: inout CGPoint, right: CGPoint) {
        left = CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    public static func -= (left: inout CGPoint, right: CGPoint) {
        left = CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
    
    public func distance(to otherPoint: CGPoint) -> CGFloat {
        let diff = self - otherPoint
        return sqrt(pow(diff.x, 2) + pow(diff.y, 2))
    }
}
