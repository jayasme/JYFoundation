//
//  Sequence+JY.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/18.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation

extension Sequence {
    
    public func jy_reduce<T>(body: (_ currentElement: Self.Iterator.Element, _ currentValue: T) -> T, initalValue: T) -> T {
        var finalValue: T = initalValue
        self.forEach{ (element) in
            finalValue = body(element, finalValue)
        }
        return finalValue
    }
}
