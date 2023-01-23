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
    
    func applyTheme() {
        self.backgroundColor = self.styleSheet?.background?.style(by: self.themes).first
    }
    
    func passthroughThemes() {
        for subview in self.subviews {
            guard let subview = subview as? JYThemeful else {
                return
            }
            subview.themes = self.themes
        }
    }
    
    override open func addSubview(_ view: UIView) {
        guard let view = view as? JYThemeful else {
            return
        }
        view.themes = self.themes
    }
}
