//
//  UIImage+JY.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/30.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit

extension UIImage {
    
    public static func jy_imageWithColor(_ color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    public func jy_resize(with maxSize: CGSize) -> UIImage {
        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxSize.width, height: size.height / size.width * maxSize.height)
        } else {
            newSize = CGSize(width: size.width / size.height * maxSize.width, height: maxSize.height)
        }
        
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
