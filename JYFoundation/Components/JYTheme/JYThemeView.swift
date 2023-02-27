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
    open var themes: [JYTheme] = [] {
        didSet {
            self.applyTheme()
            self.passthroughThemes()
        }
    }
    
    open var styleSheet: JYStyleSheet? {
        didSet {
            self.applyTheme()
        }
    }
    
    open func willApplyTheme() { }
    
    func applyTheme() {
        self.willApplyTheme()
        self.backgroundColor = self.styleSheet?.backgroundColor?.style(by: self.themes).first ?? .clear
        self.layer.borderColor = self.styleSheet?.borderColor?.style(by: self.themes).first?.cgColor ?? UIColor.clear.cgColor
        self.didApplyTheme()
    }
    
    open func didApplyTheme() { }
    
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
