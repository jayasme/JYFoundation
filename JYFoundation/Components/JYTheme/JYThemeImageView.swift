//
//  JYThemeImageView.swift
//  JYFoundation
//
//  Created by 荣超 on 2023/2/2.
//  Copyright © 2023 jayasme. All rights reserved.
//

import Foundation
import UIKit


open class JYThemeImageView: UIImageView, JYThemeful {
    
    public var themes: [JYTheme] = [] {
        didSet {
            // check if themes are the changed
            if (self.themes != oldValue) {
                self.applyThemes()
            }
        }
    }
    
    public var styleSheet: JYStyleSheet? {
        didSet {
            self.applyThemes()
        }
    }
    
    open override var image: UIImage? {
        get {
            return super.image
        }
        set {
            super.image = self.getStyledImage(image: newValue)
        }
    }
    
    public var overridedBackgroundColor: UIColor? {
        didSet {
            self.applyThemes()
        }
    }
    
    public var overrideBorderColor: UIColor? {
        didSet {
            self.applyThemes()
        }
    }
    
    public var overrideForegroundColor: UIColor? {
        didSet {
            self.applyThemes()
        }
    }
    
    public var overridedFont: UIFont? {
        didSet {
            self.applyThemes()
        }
    }
    
    func applyThemes() {
        if let overridedBackgroundColor = self.overridedBackgroundColor {
            self.backgroundColor = overridedBackgroundColor
        } else {
            self.backgroundColor = self.styleSheet?.backgroundColor?.style(by: self.themes).first ?? .clear
        }
        
        if let overrideBorderColor = self.overrideBorderColor {
            self.layer.borderColor = overrideBorderColor.cgColor
        } else {
            self.layer.borderColor = self.styleSheet?.borderColor?.style(by: self.themes).first?.cgColor ?? UIColor.clear.cgColor
        }
        self.image = self.getStyledImage(image: self.image)
    }
    
    func getStyledImage(image: UIImage?) -> UIImage? {
        var image = image
        guard image != nil else {
            return nil
        }
        if #available(iOS 13.0, *), let foregroundColor = self.overrideForegroundColor ?? self.styleSheet?.foregroundColor?.style(by: self.themes).first {
            image = image!.withTintColor(foregroundColor, renderingMode: .alwaysOriginal)
        }
        if let font = self.overridedFont ?? self.styleSheet?.font?.style(by: self.themes).first {
            image = image!.jy_resize(with: CGSize(width: font.pointSize, height: font.pointSize))
        }
        return image
    }
}
