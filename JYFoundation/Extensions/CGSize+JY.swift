//
//  CGSize+JY.swift
//  JYFoundation
//
//  Created by 荣超 on 2023/3/1.
//  Copyright © 2023 jayasme. All rights reserved.
//

import Foundation
import UIKit

extension CGSize {
    
    public static func + (left: CGSize, right: CGSize) -> CGSize {
        return CGSize(width: left.width + right.width, height: right.height + right.height)
    }
    
    public static func += (left: inout CGSize, right: CGSize) {
        left.width += right.width
        left.height += right.height
    }
    
    
}
