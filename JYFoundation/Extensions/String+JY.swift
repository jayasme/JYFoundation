//
//  String+JY.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/12.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit

extension String {
    
    public func jy_emptyToNil() -> String? {
        return self == "" ? nil : self
    }
    
    public func jy_blankToNil() -> String? {
        return self.trimmingCharacters(in: .whitespacesAndNewlines) == "" ? nil : self
    }
    
    public func jy_rangeAll(of string: String) -> [String.Index] {
        var results: [String.Index] = []
        var index: String.Index? = startIndex
        repeat {
            index = range(of: string, options: [], range: index!..<endIndex, locale: nil)?.lowerBound
            
            if index != nil {
                results.append(index!)
                index = self.index(index!, offsetBy: 1)
            }
        } while(index != nil)
        
        return results
    }
    
    public func jy_toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
    
    public func jy_fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    public func jy_substring(start: Int, length: Int? = nil) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: start)
        if let length = length {
            let endIndex = self.index(startIndex, offsetBy: length)
            return String(self[startIndex..<endIndex])
        }
        return String(self[startIndex...])
    }
    
    public func jy_sha1() -> String {
        guard let sourceData = data(using: .utf8) else {
            return ""
        }
        var result = Data(count: Int(CC_SHA1_DIGEST_LENGTH))
        _ = result.withUnsafeMutableBytes {resultPtr in
            sourceData.withUnsafeBytes {(bytes: UnsafePointer<UInt8>) in
                CC_SHA1(bytes, CC_LONG(sourceData.count), resultPtr)
            }
        }
        return result.hexString()
    }
    
    // operator overrides
    
    public static func + (left: String, right: Int) -> String {
        return left + String(right)
    }
    
    public static func + (left: String, right: CGFloat) -> String {
        return left + String(format: "%f", right)
    }
    
    public static func + (left: String, right: Double) -> String {
        return left + String(format: "%lf", right)
    }
    
    public static func += (left: inout String, right: Int) {
        left += String(right)
    }
    
    public static func += (left: inout String, right: CGFloat) {
        left += String(format: "%f", right)
    }
    
    public static func += (left: inout String, right: Double) {
        left += String(format: "%lf", right)
    }
}

