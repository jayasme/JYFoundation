//
//  String+Regex.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/12.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation

extension String {
    
    public func isMatch(with pattern: String, caseSensitive: Bool = true) -> Bool {
        var regex : NSRegularExpression!
        do {
            if caseSensitive {
                regex = try NSRegularExpression(pattern: pattern, options: [])
            } else {
                regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            }
            return regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.count)) != nil
        }
        catch {
            return false
        }
    }
    
    public func isValidPhone() -> Bool {
        return isMatch(with: "^1\\d{10}$")
    }
    
    public func isNumberic() -> Bool {
        return isMatch(with: "^\\d*$")
    }
    
    public func isNumberic(digits: Int) -> Bool {
        return isMatch(with: String(format: "^\\d{%d}$", digits))
    }
}
