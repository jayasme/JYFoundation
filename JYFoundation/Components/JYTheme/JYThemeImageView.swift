//
//  JYThemeImageView.swift
//  JYFoundation
//
//  Created by 荣超 on 2023/2/2.
//  Copyright © 2023 jayasme. All rights reserved.
//

import Foundation
import UIKit


open class JYThemeImageView: UIImageView, JYThemeful {
    
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
    
    open override var image: UIImage? {
        get {
            return super.image
        }
        set {
            super.image = self.getStyledImage(image: newValue)
        }
    }
    
    func applyTheme() {
        self.backgroundColor = self.styleSheet?.backgroundColor?.style(by: self.themes).first ?? .clear
        self.image = self.getStyledImage(image: self.image)
    }
    
    func getStyledImage(image: UIImage?) -> UIImage? {
        var image = image
        guard image != nil else {
            return nil
        }
        if #available(iOS 13.0, *), let foregroundColor = self.styleSheet?.foregroundColor?.style(by: self.themes).first {
            image = image!.withTintColor(foregroundColor, renderingMode: .alwaysOriginal)
        }
        if let font = self.styleSheet?.font?.style(by: self.themes).first {
            image = image!.jy_resize(with: CGSize(width: font.pointSize, height: font.pointSize))
        }
        return image
    }
}
