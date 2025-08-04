//
//  JYThemeActivityIndicatorView.swift
//  JYFoundation
//
//  Created by 荣超 on 2025/8/4.
//  Copyright © 2025 jayasme. All rights reserved.
//

import Foundation
import UIKit

open class JYThemeActivityIndicatorView: UIActivityIndicatorView, JYThemeful {
    
    open var themes: [JYTheme] = [] {
        didSet {
            // check if themes are the changed
            if (self.themes != oldValue) {
                self.applyThemes()
            }
        }
    }
    
    open var styleSheet: JYStyleSheet? {
        didSet {
            self.applyThemes()
        }
    }
    
    public var overrideTextColor: UIColor? {
        didSet {
            self.applyThemes()
        }
    }
    
    open func applyThemes() {
        if let overrideTextColor = self.overrideTextColor {
            self.color = overrideTextColor
        } else {
            self.color = self.styleSheet?.foregroundColor?.style(by: self.themes).first ?? .clear
        }
    }
}
