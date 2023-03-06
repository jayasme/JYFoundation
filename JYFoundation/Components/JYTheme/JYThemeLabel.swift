//
//  JYThemeLabel.swift
//  JYFoundation
//
//  Created by 荣超 on 2023/1/23.
//  Copyright © 2023 jayasme. All rights reserved.
//

import Foundation
import UIKit

open class JYThemeLabel: UILabel, JYThemeful {
    
    public var themes: [JYTheme] = [] {
        didSet {
            self.applyThemes()
        }
    }
    
    public var styleSheet: JYStyleSheet? {
        didSet {
            self.applyThemes()
        }
    }
    
    open func applyThemes() {
        self.backgroundColor = self.styleSheet?.backgroundColor?.style(by: self.themes).first ?? .clear
        self.textColor = self.styleSheet?.foregroundColor?.style(by: self.themes).first ?? .clear
        self.layer.borderColor = self.styleSheet?.borderColor?.style(by: self.themes).first?.cgColor ?? UIColor.clear.cgColor
        self.font = self.styleSheet?.font?.style(by: self.themes).first
    }
}
