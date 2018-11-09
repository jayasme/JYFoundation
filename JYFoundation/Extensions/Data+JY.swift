//
//  Data+JY.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/23.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation


extension Data {
    
    public func hexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
