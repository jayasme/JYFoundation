//
//  UIFont+JY.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/17.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit

extension UIFont {
    
    public static func jy_lightSystemFont(ofSize size: CGFloat) -> UIFont {
        if #available(iOS 8.2, *) {
            return UIFont.systemFont(ofSize: size, weight: .light)
        } else {
            return UIFont.systemFont(ofSize: size)
        }
    }
}
