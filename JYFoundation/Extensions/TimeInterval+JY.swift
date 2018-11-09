//
//  TimeInterval+JY.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/28.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation

extension TimeInterval {
    
    public func stringValue() -> String {
        let minutes = Int(self / 60)
        let seconds = Int(self) - minutes * 60
        
        if minutes > 0 {
            return String(format: "%d'%d\"", minutes, seconds)
        } else {
            return String(format: "%d\"", seconds)
        }
    }
}
