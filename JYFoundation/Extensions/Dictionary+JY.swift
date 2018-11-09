//
//  Any+JY.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/8/9.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation

extension Dictionary {
    public func jy_toJsonString() -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions.prettyPrinted) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
}
