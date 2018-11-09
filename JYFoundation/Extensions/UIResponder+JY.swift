//
//  UIResponder+JY.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/27.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit

extension UIResponder {
    
    // MARK: default identifiers
    
    public static func defaultBundle() -> Bundle {
        return Bundle(for: self)
    }

    private static var nibCache: [String: UINib] = [:]
    public static func defaultNib() -> UINib? {
        let nibName = defaultNibName()
        let bundle = defaultBundle()
        
        if let nib = nibCache[nibName] {
            return nib
        } else {
            if bundle.url(forResource: nibName, withExtension: "nib") != nil {
                let nib = UINib(nibName: nibName, bundle: bundle)
                nibCache[nibName] = nib
                return nib
            } else {
                return nil
            }
        }
    }
    
    public static func defaultNibName() -> String {
        return NSStringFromClass(self).components(separatedBy: ".").last ?? ""
    }
    
    public static func defaultIdentifier() -> String {
        return NSStringFromClass(self).components(separatedBy: ".").last ?? ""
    }
    
    public func defaultNib() -> UINib? {
        return type(of: self).defaultNib()
    }
    
    public func defaultNibName() -> String {
        return type(of: self).defaultNibName()
    }
    
    public func defaultIdentifier() -> String {
        return type(of: self).defaultIdentifier()
    }
}
