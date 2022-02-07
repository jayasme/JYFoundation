//
//  JYBlurView.swift
//  JYFoundation
//
//  Created by 荣超 on 2021/12/31.
//  Copyright © 2021 jayasme. All rights reserved.
//

import Foundation
import UIKit

public class JYBlurView: UIVisualEffectView {
  
    private var aniamtor: UIViewPropertyAnimator!
    
    convenience public init(style: UIBlurEffect.Style) {
        let effect = UIBlurEffect(style: style)
        self.init(effect: effect)
    }
        
    private override init(effect: UIVisualEffect?) {
        super.init(effect: effect)
        self.commonInit()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.aniamtor = UIViewPropertyAnimator(duration: 1, curve: .linear) {
            self.effect = UIBlurEffect(style: self.style)
            self.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    public var style: UIBlurEffect.Style = .extraLight {
        didSet {
            self.aniamtor = UIViewPropertyAnimator(duration: 1, curve: .linear) {
                self.effect = UIBlurEffect(style: self.style)
                self.translatesAutoresizingMaskIntoConstraints = false
            }
            self.aniamtor.fractionComplete = max(0, min(100, CGFloat(blurRadius) / 100.0))
        }
    }
    
    public var blurRadius: Int = 100 {
        didSet {
            self.aniamtor.fractionComplete = max(0, min(100, CGFloat(blurRadius) / 100.0))
        }
    }
}
