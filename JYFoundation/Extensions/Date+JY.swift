//
//  Date+JY.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/22.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation

extension Date {
    
    public init?(dateString: String, format: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        guard let date = formatter.date(from: dateString) else {
            return nil
        }
        
        self.init(timeIntervalSince1970: date.timeIntervalSince1970)
    }
    
    public static func now() -> Date {
        return Date(timeIntervalSinceNow: 0)
    }
    
    public func stringValue(with format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    public func descriptionString() -> String {
        let interval = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self, to: Date.now())
        if let year = interval.year, year >= 1 {
            return String(format: "%d年前", year)
        } else if let month = interval.month, month >= 1 {
            return String(format: "%d个月前", month)
        } else if let day = interval.day, day >= 1 {
            return String(format: "%d天前", day)
        } else if let hour = interval.hour, hour >= 1 {
            return String(format: "%d小时前", hour)
        } else if let minute = interval.minute, minute >= 1 {
            return String(format: "%d分钟前", minute)
        }
        
        return "刚刚"
    }
}
