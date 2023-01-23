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
    
    public var background: JYThemeStyle<UIColor>?
    public var foreground: JYThemeStyle<UIColor>?
    public var font: JYThemeStyle<UIFont>?
}

public class JYThemeStyle<T> {

    internal var styles: [(themes: [JYTheme], style: T)] = []
    
    public init() { }
    
    public func addStyle(for themes: [JYTheme], style: T) {
        styles.append((themes: themes, style: style))
    }

    public func removeTheme(by themes: [JYTheme]) {
        styles.removeAll { tuple in
            tuple.themes.allSatisfy{ themes.contains($0) }
        }
    }
    
    public func style(by themes: [JYTheme]) -> [T] {
        styles.filter { tuple in
            tuple.themes.allSatisfy{ themes.contains($0) }
        }.map { $0.style }
    }
}
