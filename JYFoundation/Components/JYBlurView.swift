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
  
    private var aniamtor: UIViewPropertyAnimator!
    
    public init(style: UIBlurEffect.Style) {
        self.style = style
        super.init(effect: nil)
        self.aniamtor = UIViewPropertyAnimator(duration: 1, curve: .linear) {[unowned self] in
            self.effect = UIBlurEffect(style: style)
            self.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError()
    }
    
    private func updateBlurRadius() {
        self.aniamtor.fractionComplete = max(0, min(1, CGFloat(self.blurRadius) / 100.0))
    }
    
    public var style: UIBlurEffect.Style {
        didSet {
            self.aniamtor = UIViewPropertyAnimator(duration: 1, curve: .linear) {[unowned self] in
                self.effect = UIBlurEffect(style: self.style)
                self.translatesAutoresizingMaskIntoConstraints = false
            }
            self.updateBlurRadius()
        }
    }
    
    public var blurRadius: Int = 8 {
        didSet {
            self.updateBlurRadius()
        }
    }
}
