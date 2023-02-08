//
//  JYThemeScrollView.swift
//  JYFoundation
//
//  Created by 荣超 on 2023/2/8.
//  Copyright © 2023 jayasme. All rights reserved.
//

import Foundation
import UIKit

class JYThemeScrollView: UIScrollView, JYThemeful {
    
    var themes: [JYTheme] = [] {
        didSet {
            self.applyTheme()
            self.passthroughThemes()
        }
    }
    
    var styleSheet: JYStyleSheet? {
        didSet {
            self.applyTheme()
        }
    }
    
    func applyTheme() {
        self.backgroundColor = self.styleSheet?.backgroundColor?.style(by: self.themes).first ?? .clear
        self.layer.borderColor = self.styleSheet?.borderColor?.style(by: self.themes).first?.cgColor ?? UIColor.clear.cgColor
    }
    
    func passthroughThemes() {
        for subview in self.subviews {
            guard let subview = subview as? JYThemeful else {
                break
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
