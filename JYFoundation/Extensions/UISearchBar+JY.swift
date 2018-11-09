//
//  JYSearchBar+JY.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/5/28.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit

extension UISearchBar {
    
    public var jy_cancelButton: UIButton? {
        let key = String(format: "%@_%d_%@", "UISearchBar", hash, "cancelButon")
        var button: UIButton? = jy_getAssociatedObject(key: key) as? UIButton
        if button == nil {
            subviews.first?.subviews.forEach { (view) in
                if view is UIButton {
                    button = view as? UIButton
                    jy_setAssociatedObject(key: key, object: view, policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                }
            }
        }
        return button
    }
}
