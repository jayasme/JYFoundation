//
//  Calendar+JY.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/22.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation


extension Calendar {
    
    public func jy_isDateInThisYear(date: Date) -> Bool {
        return Date.now().stringValue(with: "yyyy") == date.stringValue(with: "yyyy")
    }
}
