//
//  CGFloat+JY.swift
//  JYFoundation
//
//  Created by 荣超 on 2022/1/29.
//  Copyright © 2022 jayasme. All rights reserved.
//

import UIKit

extension CGFloat {
    
    func random(max: CGFloat) -> CGFloat {
        return CGFloat(drand48() * Double(max))
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return CGFloat(drand48() * Double(max - min)) + min
    }
}
