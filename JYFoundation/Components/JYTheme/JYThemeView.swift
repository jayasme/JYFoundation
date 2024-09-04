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
            self.applyThemes()
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
    
    override open func insertSubview(_ view: UIView, at index: Int) {
        super.insertSubview(view, at: index)
        guard let view = view as? JYThemeful else {
            return
        }
        view.themes = self.themes
    }
    
    override open func insertSubview(_ view: UIView, aboveSubview siblingSubview: UIView) {
        super.insertSubview(view, aboveSubview: siblingSubview)
        guard let view = view as? JYThemeful else {
            return
        }
        view.themes = self.themes
    }
    
    override open func insertSubview(_ view: UIView, belowSubview siblingSubview: UIView) {
        super.insertSubview(view, belowSubview: siblingSubview)
        guard let view = view as? JYThemeful else {
            return
        }
        view.themes = self.themes
    }
}
