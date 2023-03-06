//
//  UIView+JY.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/6.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit
import PromiseKit

extension UIView {

    public class JY {
        private unowned let view: UIView
        
        init(view: UIView) {
            self.view = view
        }
        
        public var animation: JYAnimationService {
            get {
                return JYAnimationService(view: self.view)
            }
        }
    }
    
    public var jy: JY {
        get {
            return JY(view: self)
        }
    }
    
    /// Get or set visibility of the view.
    public var isVisible: Bool {
        get {
            return !isHidden
        }
        set(value) {
            isHidden = !value
        }
    }
    
    /// Find the view mathces the condition.
    public func findSubViews(where predicate: (UIView) -> Bool) -> [UIView] {
        var result: [UIView] = []
        if (predicate(self)) {
            result += self
        }
        for subView in self.subviews {
            result += subView.findSubViews(where: predicate)
        }
        return result
    }
    
    /// Get the root view matches the condition.
    public func findRootView(where predicate: (UIView) -> Bool) -> UIView? {
        var current: UIView? = self.superview
        var array: [UIView] = []
        while(true) {
            if let c = current {
                if predicate(c) {
                    array.append(c)
                }
                current = c.superview
            } else {
                break
            }
        }
        return array.last
    }
}
