//
//  JYTheme.swift
//  JYFoundation
//
//  Created by 荣超 on 2023/1/23.
//  Copyright © 2023 jayasme. All rights reserved.
//

import Foundation
import UIKit

extension Notification.Name {
    
    public static let JYThemeWillChange = Notification.Name("JYThemeWillChange")
    public static let JYThemeDidChange = Notification.Name("JYThemeDidChange")
}

public class JYThemeManager {
    
    public static let shared: JYThemeManager = JYThemeManager()
    
    public var themes: [JYTheme] = [] {
        willSet {
            NotificationCenter.default.post(
                name: NSNotification.Name.JYThemeWillChange,
                object: nil,
                userInfo: [
                    "oldThemes": self.themes,
                    "newThemes": newValue
                ]
            )
        }
        didSet {
            NotificationCenter.default.post(
                name: NSNotification.Name.JYThemeDidChange,
                object: nil,
                userInfo: ["themes": self.themes]
            )
        }
    }
}

public class JYTheme: Hashable {
    public var name: String
    
    public init(name: String) {
        self.name = name
    }
    
    public static func == (lhs: JYTheme, rhs: JYTheme) -> Bool {
        return lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
    }
}

open class JYStyleSheet {
    
    public var backgroundColor: JYThemeStyle<UIColor>?
    public var foregroundColor: JYThemeStyle<UIColor>?
    public var borderColor: JYThemeStyle<UIColor>?
    public var font: JYThemeStyle<UIFont>?
    
    public init(backgroundColor: JYThemeStyle<UIColor>? = nil,
                foregroundColor: JYThemeStyle<UIColor>? = nil,
                borderColor: JYThemeStyle<UIColor>? = nil,
                font: JYThemeStyle<UIFont>? = nil) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.borderColor = borderColor
        self.font = font
    }
    
    public func toAttributedStringKeys(themes: [JYTheme]) -> [NSAttributedString.Key: Any] {
        var keys: [NSAttributedString.Key: Any] = [:]
        if let backgroundColor = self.backgroundColor, let backgroundColorValue = backgroundColor.style(by: themes).first {
            keys[NSAttributedString.Key.backgroundColor] = backgroundColorValue
        }
        if let foregroundColor = self.foregroundColor, let foregroundColorValue = foregroundColor.style(by: themes).first {
            keys[NSAttributedString.Key.foregroundColor] = foregroundColorValue
        }
        if let font = self.font, let fontValue = font.style(by: themes).first {
            keys[NSAttributedString.Key.font] = fontValue
        }
        return keys
    }
    
    public static func combine(styleSheets: [JYStyleSheet]) -> JYStyleSheet? {
        guard var current = styleSheets.first else {
            return nil
        }
        
        styleSheets[1...].forEach { styleSheet in
            if let backgroundColor = styleSheet.backgroundColor {
                current.backgroundColor = styleSheet.backgroundColor
            }
            if let foregroundColor = styleSheet.foregroundColor {
                current.foregroundColor = styleSheet.foregroundColor
            }
            if let borderColor = styleSheet.borderColor {
                current.borderColor = styleSheet.borderColor
            }
            if let font = styleSheet.font {
                current.font = styleSheet.font
            }
        }
        
        return current
    }
}

public class JYThemeStyle<T> {

    internal var styles: [(themes: [JYTheme], style: T)] = []
    
    public init() { }
    
    public func addStyle(for themes: JYTheme, style: T) {
        self.styles.append((themes: [themes], style: style))
    }
    
    public func addStyle(for themes: [JYTheme], style: T) {
        self.styles.append((themes: themes, style: style))
    }

    public func remove(themes: [JYTheme]) {
        self.styles.removeAll { tuple in
            tuple.themes.allSatisfy{ themes.contains($0) }
        }
    }
    
    public func removeAll() {
        self.styles.removeAll()
    }
    
    public func style(by themes: [JYTheme]) -> [T] {
        self.styles.filter { tuple in
            tuple.themes.allSatisfy{ themes.contains($0) }
        }.map { $0.style }
    }
}

extension [JYTheme]: Equatable {
    
    public static func == (lhs: [JYTheme], rhs: [JYTheme]) -> Bool {
        let lhss = lhs.reduce("") { partialResult, theme in
            return partialResult + "|" + theme.name
        }
        let rhss = rhs.reduce("") { partialResult, theme in
            return partialResult + "|" + theme.name
        }
        return lhss == rhss
    }
}
