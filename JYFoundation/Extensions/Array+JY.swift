//
//  Array+JY.swift
//  JYFoundation
//
//  Created by 荣超 on 2023/2/5.
//  Copyright © 2023 jayasme. All rights reserved.
//

import Foundation

extension Array {
    
    public static func + (left: Array, right: Array) -> Array {
        var result: Array = left
        result.append(contentsOf: right)
        return result
    }
    
    public static func += (left: inout Array, right: Element) {
        left.append(right)
    }
    
    public static func += (left: inout Array, right: Array) {
        left.append(contentsOf: right)
    }
    
    public static func fill(count: Int, with element: Element) -> Self {
        var array = Self.init()
        for _ in 0..<count {
            array.append(element)
        }
        return array
    }
    
    public func emptyToNil() -> Self? {
        return self.count > 0 ? self : nil
    }
}

extension Array where Element: Equatable {
    
    public func contains(of element: Element) -> Bool {
        return self.contains(where: { $0 == element })
    }
}

extension Array where Element: Hashable {
    
    public func contains(of element: Element) -> Bool {
        return self.contains(where: { $0.hashValue == element.hashValue })
    }
    
    public func firstIndex(of element: Element) -> Int? {
        return self.firstIndex(where: { $0.hashValue == element.hashValue })
    }

    public func lastIndex(of element: Element) -> Int? {
        return self.lastIndex(where: { $0.hashValue == element.hashValue })
    }
}
