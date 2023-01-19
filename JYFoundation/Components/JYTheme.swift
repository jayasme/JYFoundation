//
//  ThemeManager.swift
//  JYFoundation
//
//  Created by 荣超 on 2023/1/17.
//

import Foundation
import UIKit

public class JYThemeManager {

    internal var themes: [String: JYTheme] = [:]
    
    public func addTheme(key: String, color theme: JYTheme) {
        themes[key] = theme
    }
    
    public func removeTheme(key: String) {
        themes.removeValue(forKey: key)
    }
    
    public func theme(by key: String) -> JYTheme? {
        return themes[key]
    }
}

public protocol JYThemeful: AnyObject {
    var theme: JYTheme? { get set }
    func onThemeApply(fonts: JYTheme.JYFontStyles, colors: JYTheme.JYColorStyles)
    func onThemeClear()
}

public class JYTheme {

    public typealias JYThemeKey = String
    public typealias JYFontStyles = [JYThemeKey: CGFont]
    public typealias JYColorStyles = [JYThemeKey: CGColor]
    
    internal var fontStyles: JYFontStyles = [:]
    internal var colorStyles: JYColorStyles = [:]
    
    public func addStyle(key: JYThemeKey, color style: CGColor) {
        colorStyles[key] = style
    }
    
    public func addStyle(key: JYThemeKey, font style: CGFont) {
        fontStyles[key] = style
    }
    
    public func removeTheme(key: JYThemeKey) {
        fontStyles.removeValue(forKey: key)
        colorStyles.removeValue(forKey: key)
    }
    
    public func theme(fontBy key: JYThemeKey) -> CGFont? {
        return fontStyles[key]
    }
    
    public func theme(colorBy key: JYThemeKey) -> CGColor? {
        return colorStyles[key]
    }
}

open class JYThemeView: UIView, JYThemeful {
    
    public var theme: JYTheme? {
        didSet {
            guard let theme = theme else {
                self.onThemeClear()
                return
            }
            self.onThemeApply(fonts: theme.fontStyles, colors: theme.colorStyles)
            
            // notify sub views
            for subview in self.subviews {
                (subview as? JYThemeful)?.theme = theme
            }
        }
    }
    
    open func onThemeApply(fonts: JYTheme.JYFontStyles, colors: JYTheme.JYColorStyles) { }
    
    open func onThemeClear() { }
    
    open override func addSubview(_ view: UIView) {
        super.addSubview(view)
        (view as? JYThemeful)?.theme = theme
    }
}

open class JYThemeLabel: UILabel, JYThemeful {
    
    public var theme: JYTheme? {
        didSet {
            guard let theme = theme else {
                self.onThemeClear()
                return
            }
            self.onThemeApply(fonts: theme.fontStyles, colors: theme.colorStyles)
        }
    }
    
    open func onThemeApply(fonts: JYTheme.JYFontStyles, colors: JYTheme.JYColorStyles) { }
    
    open func onThemeClear() { }
}

open class JYThemeTextField: UITextField, JYThemeful {
    
    public var theme: JYTheme? {
        didSet {
            guard let theme = theme else {
                self.onThemeClear()
                return
            }
            self.onThemeApply(fonts: theme.fontStyles, colors: theme.colorStyles)
        }
    }
    
    open func onThemeApply(fonts: JYTheme.JYFontStyles, colors: JYTheme.JYColorStyles) { }
    
    open func onThemeClear() { }
}

open class JYThemeTextView: UITextView, JYThemeful {
    
    public var theme: JYTheme? {
        didSet {
            guard let theme = theme else {
                self.onThemeClear()
                return
            }
            self.onThemeApply(fonts: theme.fontStyles, colors: theme.colorStyles)
        }
    }
    
    open func onThemeApply(fonts: JYTheme.JYFontStyles, colors: JYTheme.JYColorStyles) { }
    
    open func onThemeClear() { }
}
