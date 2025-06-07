//
//  Sequence+JY.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/18.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation

extension Sequence {
    
    public func mapArray<T>(_ transform: (Element) throws -> [T]) rethrows -> [T] {
        var result: [T] = []
        
        for element in self {
            let it = try transform(element)
            result += it
        }
        
        return result
    }
}
