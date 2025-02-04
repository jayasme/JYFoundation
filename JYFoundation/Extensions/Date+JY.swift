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
    
    public static var now: Date {
        return Date(timeIntervalSinceNow: 0)
    }
    
    public static func today(calendar: Calendar = .init(identifier: .gregorian)) -> Date? {
        let components = calendar.dateComponents([.year, .month, .day], from: .now)
        if let today = calendar.date(from: components) {
            return today
        }
        return nil
    }
    
    public func isSameDay(with other: Date, calendar: Calendar = .init(identifier: .gregorian)) -> Bool {
        let selfComponents = calendar.dateComponents([.day], from: self)
        let otherComponents = calendar.dateComponents([.day], from: other)
        
        return selfComponents.year == otherComponents.year && selfComponents.month == otherComponents.month && selfComponents.day == otherComponents.day
    }
}
