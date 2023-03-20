//
//  JYStack.swift
//  JYFoundation
//
//  Created by 荣超 on 2023/3/19.
//  Copyright © 2023 jayasme. All rights reserved.
//

import Foundation

public class JYStack<Element> {
    private var capacity: Int
    private var data: [Element] = []
    
    public var count: Int {
        return self.data.count
    }
    
    public init(capacity: Int = 0) {
        self.capacity = capacity
    }
    
    public func push(element: Element) {
        if (self.capacity > 0 && self.data.count >= self.capacity) {
            self.data.remove(at: 0)
        }
        
        self.data += element
    }
    
    public func pop() -> Element? {
        guard self.data.count > 0 else {
            return nil
        }
        
        return self.data.removeLast()
    }
    
    public func clear() {
        self.data.removeAll()
    }
}
