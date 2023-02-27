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
    
    public static func now(includesTime: Bool = true) -> Date {
        let now = Date(timeIntervalSinceNow: 0)
        if (!includesTime) {
            let calendar = Calendar(identifier: .iso8601)
            let components = calendar.dateComponents([.year, .month, .day], from: now)
            if let newNow = calendar.date(from: components) {
                return newNow
            }
        }
        return now
    }
    
    public func stringValue(with format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    // Properties
    
    public var year: Int {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.component(.year, from: self)
    }
    
    public var month: Int {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.component(.month, from: self)
    }
    
    public var monthLong: String {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.monthSymbols[self.month]
    }
    
    public var monthShort: String {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.shortMonthSymbols[self.month]
    }
    
    public var monthVeryShort: String {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.veryShortStandaloneMonthSymbols[self.month]
    }
    
    public var day: Int {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.component(.day, from: self)
    }
    
    public var weekday: Int {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.component(.weekday, from: self)
    }

    public var weekdayLong: String {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.standaloneWeekdaySymbols[self.weekday - 1]
    }
    
    public var weekdayShort: String {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.shortWeekdaySymbols[self.weekday - 1]
    }
    
    public var weekdayVeryShort: String {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.veryShortStandaloneWeekdaySymbols[self.weekday - 1]
    }
    
    public var hour12: Int {
        let hour = self.hour24
        if (hour > 12) {
            return hour - 12
        }
        return hour
    }
    
    public var hour12Period: String {
        let calendar = Calendar(identifier: .iso8601)
        let hour = self.hour24
        if (hour > 12) {
            return calendar.pmSymbol
        }
        return calendar.amSymbol
    }
    
    public var hour24: Int {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.component(.hour, from: self)
    }
    
    public var minute: Int {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.component(.minute, from: self)
    }
    
    public var second: Int {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.component(.second, from: self)
    }
    
    // local calendars
    
    public var rocYear: Int {
        let calendar = Calendar(identifier: .republicOfChina)
        return calendar.component(.year, from: self)
    }
    
    public var chineseMonth: Int {
        let calendar = Calendar(identifier: .chinese)
        return calendar.component(.month, from: self)
    }
    
    public var chineseMonthLong: String {
        let months = ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"]
        return months[self.chineseMonth - 1]
    }
    
    public var chineseMonthShort: String {
        let months = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二"]
        return months[self.chineseMonth - 1]
    }
    
    public var chineseDay: Int {
        let calendar = Calendar(identifier: .chinese)
        return calendar.component(.day, from: self)
    }
    
    public var chineseDayString: String {
        let days = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        let day = self.chineseDay
        if (day <= 10) {
            return "初" + days[day - 1]
        }
        if (day < 20) {
            return "十" + days[day % 10 - 1]
        }
        if (day == 20) {
            return "二十"
        }
        if (day < 30) {
            return "廿" + days[day % 10 - 1]
        }
        if (day == 30) {
            return "三十"
        }
        return "三" + days[day % 10 - 1]
    }
    
    public var japaneseYear: Int {
        let calendar = Calendar(identifier: .japanese)
        return calendar.component(.year, from: self)
    }
}
