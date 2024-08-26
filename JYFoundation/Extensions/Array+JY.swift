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
    
    public static func + (left: Array, right: Element) -> Array {
        var result: Array = left
        result.append(right)
        return result
    }
    
    public static func + (left: Element, right: Array) -> Array {
        var result: Array = right
        result.insert(left, at: 0)
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
    
    public func exclude(where predicate: (Element) -> Bool) -> [Element] {
        return self.filter{ !predicate($0) }
    }
    
    public func firstIndex(where predicate: (Element) -> Bool, from index: Int) -> Int? {
        for i in index..<self.count {
            if (predicate(self[i])) {
                return i
            }
        }
        return nil
    }
    
    public func lastIndex(where predicate: (Element) -> Bool, from index: Int) -> Int? {
        for i in 0...index {
            if (predicate(self[index - i])) {
                return index - i
            }
        }
        return nil
    }
    
    public func unique<E: Equatable>(_ filter: (Element) -> E) -> [Element] {
        var result: [Element] = []
        for ele in self {
            let key = filter(ele)
            if !result.map({ filter($0) }).contains(key) {
                result.append(ele)
            }
        }
        return result
    }
    
    public subscript(range: PartialRangeFrom<Int>) -> [Element] {
        return Array<Element>(self[range.lowerBound..<self.count])
    }
    
    public subscript(range: PartialRangeUpTo<Int>) -> [Element] {
        return Array<Element>(self[0...range.upperBound])
    }
    
    public subscript(safe range: Range<Index>) -> ArraySlice<Element> {
        if range.endIndex > endIndex {
            if range.startIndex >= endIndex {return []}
            else {return self[range.startIndex..<endIndex]}
        }
        else {
            return self[range]
        }
    }
}

extension Array where Element: Equatable {
    
    public func contains(of element: Element) -> Bool {
        return self.contains(where: { $0 == element })
    }
    
    public func exclude(of element: Element) -> [Element] {
        return self.filter { $0 != element }
    }
    
    public func exclude(in element: [Element]) -> [Element] {
        return self.filter { !element.contains(of: $0) }
    }
    
    public func unique() -> [Element] {
        return self.unique { $0 }
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
