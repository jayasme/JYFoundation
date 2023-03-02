//
//  JYThemeView.swift
//  JYFoundation
//
//  Created by 荣超 on 2023/1/23.
//  Copyright © 2023 jayasme. All rights reserved.
//

import Foundation
import UIKit

open class JYThemeView: UIView, JYThemeful {
    public var themes: [JYTheme] = [] {
        didSet {
            self.applyTheme()
            self.passthroughThemes()
        }
    }
    
    public var styleSheet: JYStyleSheet? {
        didSet {
            self.applyTheme()
        }
    }
    
    open func applyTheme() {
        self.backgroundColor = self.styleSheet?.backgroundColor?.style(by: self.themes).first ?? .clear
        self.layer.borderColor = self.styleSheet?.borderColor?.style(by: self.themes).first?.cgColor ?? UIColor.clear.cgColor
    }
    
    func passthroughThemes() {
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
