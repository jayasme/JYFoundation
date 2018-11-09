//
//  JYError.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/16.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation

public class JYError: Error {
    private(set) public var message: String
    private(set) public var userInfo: [String: Any?]?
    
    public init(_ message: String = "", userInfo: [String: Any?]? = nil) {
        self.message = message
        self.userInfo = userInfo
        
        print(message)
    }
}
