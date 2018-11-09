//
//  UIButton+JY.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/15.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit

public enum JYButtonStyle: Int {
    case Default = 0
    case TopImageBotomText = 1
    case LeftTextRightImage = 2
}

extension UIButton {
    
    public func jy_setStyle(_ style: JYButtonStyle, spacing: CGFloat = 0) {
        
        if style == .Default {
            
            titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            
        } else if style == .LeftTextRightImage {
            
            titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageView!.bounds.size.width - spacing / 2, bottom: 0, right: imageView!.bounds.size.width + spacing / 2)
            imageEdgeInsets = UIEdgeInsets(top: 0, left: titleLabel!.bounds.size.width + spacing / 2, bottom: 0, right: -titleLabel!.bounds.size.width - spacing / 2)
            
        } else if style == .TopImageBotomText {

            titleEdgeInsets = UIEdgeInsets(top: imageView!.bounds.size.height + spacing / 2, left: -imageView!.bounds.size.width - spacing / 2, bottom: 0, right: 0)
            imageEdgeInsets = UIEdgeInsets(top: -titleLabel!.bounds.size.height - spacing / 2, left: 0, bottom: 0, right: -titleLabel!.bounds.size.width - spacing / 2)
        }
    }
    
    public func jy_setOriginalImage(_ image: UIImage, state: UIControlState) {
        setImage(image.withRenderingMode(.alwaysOriginal), for: state)
    }
    
    public func jy_setBackgroundColor(color: UIColor, state: UIControlState) {
        let image = UIImage.jy_imageWithColor(color)
        setBackgroundImage(image, for: state)
    }
}
