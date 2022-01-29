//
//  Int+JY.swift
//  JYFoundation
//
//  Created by 荣超 on 2022/1/29.
//  Copyright © 2022 jayasme. All rights reserved.
//

import Foundation

extension Int {
    
    func random(max: Int) -> Int {
        return Int(drand48() * Double(max))
    }
    
    func random(min: Int, max: Int) -> Int {
        return Int(drand48() * Double(max - min)) + min
    }
}
