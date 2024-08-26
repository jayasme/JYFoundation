//
//  JYThemeTextField.swift
//  JYFoundation
//
//  Created by 荣超 on 2023/1/23.
//  Copyright © 2023 jayasme. All rights reserved.
//

import Foundation
import UIKit

open class JYThemeTextField: UITextField, JYThemeful {
    
    public var themes: [JYTheme] = [] {
        didSet {
            self.applyThemes()
        }
    }
    
    public var styleSheet: JYStyleSheet? {
        didSet {
            self.applyThemes()
        }
    }
    
    public var overridedBackgroundColor: UIColor? {
        didSet {
            self.applyThemes()
        }
    }
    
    public var overrideTextColor: UIColor? {
        didSet {
            self.applyThemes()
        }
    }
    
    public var overridedFont: UIFont? {
        didSet {
            self.applyThemes()
        }
    }
    
    public var overrideBorderColor: UIColor? {
        didSet {
            self.applyThemes()
        }
    }
    
    open func applyThemes() {
        if let overridedBackgroundColor = self.overridedBackgroundColor {
            self.backgroundColor = overridedBackgroundColor
        } else {
            self.backgroundColor = self.styleSheet?.backgroundColor?.style(by: self.themes).first ?? .clear
        }
        
        if let overrideTextColor = self.overrideTextColor {
            self.textColor = overrideTextColor
        } else {
            self.textColor = self.styleSheet?.foregroundColor?.style(by: self.themes).first ?? .clear
        }
        
        if let overrideFont = self.overridedFont {
            self.font = overrideFont
        } else {
            self.font = self.styleSheet?.font?.style(by: self.themes).first
        }
        
        if let overrideBorderColor = self.overrideBorderColor {
            self.layer.borderColor = overrideBorderColor.cgColor
        } else {
            self.layer.borderColor = self.styleSheet?.borderColor?.style(by: self.themes).first?.cgColor ?? UIColor.clear.cgColor
        }
    }
}
