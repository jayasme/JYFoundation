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
            self.applyTheme()
        }
    }
    
    public var styleSheet: JYStyleSheet? {
        didSet {
            self.applyTheme()
        }
    }
    
    func applyTheme() {
        self.backgroundColor = self.styleSheet?.background?.style(by: self.themes).first ?? .clear
        self.textColor = self.styleSheet?.foreground?.style(by: self.themes).first ?? .clear
        self.font = self.styleSheet?.font?.style(by: self.themes).first
    }
}
