//
//  JYThemeScrollView.swift
//  JYFoundation
//
//  Created by 荣超 on 2023/2/8.
//  Copyright © 2023 jayasme. All rights reserved.
//

import Foundation
import UIKit

open class JYThemeScrollView: UIScrollView, JYThemeful {
    
    public var themes: [JYTheme] = [] {
        didSet {
            // check if themes are the changed
            if (self.themes != oldValue) {
                self.applyThemes()
            }
            self.passthroughThemes()
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
        
        if let overrideBorderColor = self.overrideBorderColor {
            self.layer.borderColor = overrideBorderColor.cgColor
        } else {
            self.layer.borderColor = self.styleSheet?.borderColor?.style(by: self.themes).first?.cgColor ?? UIColor.clear.cgColor
        }
    }
    
    open func passthroughThemes() {
        for subview in self.subviews {
            guard let subview = subview as? JYThemeful else {
                continue
            }
            subview.themes = self.themes
        }
    }
    
    override open func addSubview(_ view: UIView) {
        super.addSubview(view)
        guard let view = view as? JYThemeful else {
            return
        }
        view.themes = self.themes
    }
}
