//
//  JYBlurView.swift
//  JYFoundation
//
//  Created by 荣超 on 2021/12/31.
//  Copyright © 2021 jayasme. All rights reserved.
//

import Foundation
import UIKit

open class JYBlurView: UIVisualEffectView {
    
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
}
