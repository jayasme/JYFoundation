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
}
