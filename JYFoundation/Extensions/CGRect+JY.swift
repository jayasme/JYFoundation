//
//  CGRect.swift
//  JYFoundation
//
//  Created by 荣超 on 2023/3/12.
//  Copyright © 2023 jayasme. All rights reserved.
//

import Foundation
import UIKit

extension CGRect {
    
    public func contains(_ rect: CGRect) -> Bool {
        return rect.minX >= self.minX && rect.minY >= self.minY && rect.maxX <= self.maxX && rect.maxY <= self.maxY
    }
    
    public static func + (left: CGRect, right: CGPoint) -> CGRect {
        return CGRect(x: left.minX + right.x, y: left.minY + right.y, width: left.width, height: left.height)
    }
    
    public static func - (left: CGRect, right: CGPoint) -> CGRect {
        return CGRect(x: left.minX - right.x, y: left.minY - right.y, width: left.width, height: left.height)
    }
}
