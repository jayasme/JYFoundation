//
//  NSObject+JY.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/25.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import ObjectiveC

extension NSObject {
    
    public func jy_getAssociatedObject(key: String) -> Any? {
        let key: UnsafeRawPointer! = UnsafeRawPointer.init(bitPattern: key.hashValue)
        return objc_getAssociatedObject(self, key)
    }
    
    public func jy_setAssociatedObject(key: String, object: Any?) {
        guard let object = object else {
            jy_removeAssociationObject(key: key)
            return
        }
        
        // determin the type of association storage policy
        var policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_COPY_NONATOMIC
        if object is NSString || object is NSNumber {
            policy = .OBJC_ASSOCIATION_COPY_NONATOMIC
        } else if object is NSObject {
            policy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        } else {
            policy = .OBJC_ASSOCIATION_ASSIGN
        }

        jy_setAssociatedObject(key: key, object: object, policy: policy)
    }
    
    public func jy_setAssociatedObject(key: String, object: Any, policy: objc_AssociationPolicy) {
        let key: UnsafeRawPointer! = UnsafeRawPointer.init(bitPattern: key.hashValue)
        objc_setAssociatedObject(self, key, object, policy)
    }
    
    public func jy_removeAssociationObject(key: String) {
        let key: UnsafeRawPointer! = UnsafeRawPointer.init(bitPattern: key.hashValue)
        objc_removeAssociatedObjects(key ?? "")
    }
}
