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
    public func findSubView(where predicate: (UIView) -> Bool) -> UIView? {
        if let view = self.subviews.first(where: predicate) {
            return view
        }
        for subView in self.subviews {
            if let view = subView.findSubView(where: predicate) {
                return view
            }
        }
        return nil
    }
    
    /// Get the root view of the view. if the view is already a root view, returns itself
    public var rootView: UIView {
        var rootView: UIView = self
        while(true) {
            if let superView = rootView.superview {
                rootView = superView
            } else {
                break
            }
        }
        return rootView
    }
}
