//
//  JYBlurView.swift
//  JYFoundation
//
//  Created by 荣超 on 2021/12/31.
//  Copyright © 2021 jayasme. All rights reserved.
//

import Foundation
import UIKit

open class JYBlurView: UIVisualEffectView, JYThemeful {
    
    private var animator: UIViewPropertyAnimator?
    
    public init() {
        super.init(effect: nil)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.updateEffect()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.animator?.stopAnimation(true)
        self.animator?.finishAnimation(at: .start)
    }
    
    private func updateEffect() {
        self.effect = nil
        self.animator?.stopAnimation(true)
        self.animator?.finishAnimation(at: .start)
        
        guard let style = self.style else {
            return
        }
        
        let animator = UIViewPropertyAnimator(duration: 1, curve: .linear) { [weak self] in
            guard let self = self else { return }
            self.effect = UIBlurEffect(style: style)
        }
        
        animator.fractionComplete = max(0, min(1, self.blurRadius / 100.0))
        self.animator = animator
    }
    
    public var style: UIBlurEffect.Style? {
        didSet {
            self.updateEffect()
        }
    }
    
    public var blurRadius: CGFloat = 0 {
        didSet {
            self.animator?.fractionComplete = max(0, min(1, self.blurRadius / 100.0))
        }
    }
    
    // MARK: themeful
    open var themes: [JYTheme] = [] {
        didSet {
            // check if themes are the changed
            if (self.themes != oldValue) {
                self.applyThemes()
            }
            self.passthroughThemes()
        }
    }
    
    open var styleSheet: JYStyleSheet? {
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
    
    open func passthroughThemes() {
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
