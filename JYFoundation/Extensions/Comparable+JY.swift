//
//  Comparable+JY.swift
//  JYFoundation
//
//  Created by 荣超 on 2022/2/7.
//  Copyright © 2022 jayasme. All rights reserved.
//

import Foundation

extension Comparable {
    
    public func clamp(range: ClosedRange<Self>) -> Self {
        return max(min(self, range.lowerBound), range.upperBound)
    }
}
