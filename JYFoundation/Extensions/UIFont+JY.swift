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
    
    public func with(_ traits: UIFontDescriptor.SymbolicTraits...) -> UIFont {
      guard let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits)
                             .union(self.fontDescriptor.symbolicTraits)) else {
        return self
      }
      return UIFont(descriptor: descriptor, size: 0)
    }

    public func without(_ traits: UIFontDescriptor.SymbolicTraits...) -> UIFont {
      guard let descriptor = self.fontDescriptor.withSymbolicTraits(self.fontDescriptor.symbolicTraits
                             .subtracting(UIFontDescriptor.SymbolicTraits(traits))) else {
        return self
      }
      return UIFont(descriptor: descriptor, size: 0)
    }
}
