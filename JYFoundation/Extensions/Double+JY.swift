//
//  Double+JY.swift
//  JYFoundation
//
//  Created by 荣超 on 2022/1/29.
//  Copyright © 2022 jayasme. All rights reserved.
//

import Foundation

extension Double {
    
    func random(max: Double) -> Double {
        return Double(drand48() * Double(max))
    }
    
    func random(min: Double, max: Double) -> Double {
        return drand48() * Double(max - min) + min
    }
}
