//
//  JYAnimationService.swift
//  JYFoundation
//
//  Created by 荣超 on 2023/1/23.
//  Copyright © 2023 jayasme. All rights reserved.
//

import Foundation
import UIKit

public class JYAnimationService: NSObject, CAAnimationDelegate {
    
    public enum FromState {
        case alwaysFromValue
        case auto
    }
    
    struct StopTuple {
        var toValue: NSValue
        var removeOnComplete: Bool
        var callback: ((Bool) -> Void)?
    }
    
    private var animationMap: [String: StopTuple] = [:]
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard let animation = anim as? CABasicAnimation, let keyPath = animation.keyPath else {
            return
        }
        let animationKey = "JYAnimationService."  + keyPath
        if let tuple = animationMap[animationKey] {
            if (flag) {
                self.view.layer.setValue(tuple.toValue, forKeyPath: keyPath)
                if (tuple.removeOnComplete) {
                    self.view.layer.removeAnimation(forKey: animationKey)
                }
            }
            tuple.callback?(flag)
        }
        if (self.animationMap[animationKey] != nil) {
            self.animationMap.removeValue(forKey: animationKey)
        }
    }
    
    private unowned var view: UIView
    
    public init(view: UIView) {
        self.view = view
    }
    
    public func animate(from: NSValue, to: NSValue, keyPath: String, duration: TimeInterval, delay: TimeInterval? = nil, timingFunction: CAMediaTimingFunction? = nil, fromState: FromState = .auto, removeOnComplete: Bool = true, onComplete: ((_ flag: Bool) -> Void)? = nil) {
        
        let animationKey = "JYAnimationService."  + keyPath
        if (self.view.layer.animation(forKey: animationKey) != nil) {
            self.view.layer.removeAnimation(forKey: animationKey)
        }
        
        let animation = CABasicAnimation(keyPath: keyPath)
        if fromState == .auto, let fromValue = self.view.layer.presentation()?.value(forKeyPath: keyPath) as? NSValue {
            animation.fromValue = fromValue
        } else {
            animation.fromValue = from
        }
        animation.toValue = to
        animation.duration = duration
        animation.beginTime = CACurrentMediaTime() + (delay ?? 0)
        animation.fillMode = .forwards
        // remove manually
        animation.isRemovedOnCompletion = false
        animation.timingFunction = timingFunction
        animation.delegate = self
        self.view.layer.add(animation, forKey: animationKey)
        
        if (self.animationMap[animationKey] != nil) {
            self.animationMap.removeValue(forKey: animationKey)
        }
        let tuple = StopTuple(toValue: to, removeOnComplete: removeOnComplete, callback: onComplete)
        self.animationMap[animationKey] = tuple
    }
    
    public func popIn(duration: TimeInterval, delay: TimeInterval? = nil, timingFunction: CAMediaTimingFunction = .easeOutCubic, fromState: FromState = .auto, removeOnComplete: Bool = true, onComplete: ((_ flag: Bool) -> Void)? = nil) {
        self.animate(from: NSNumber(value: 0.0) as NSValue,
                     to: NSNumber(value: 1.0) as NSValue,
                     keyPath: "transform.scale",
                     duration: duration,
                     delay: delay,
                     timingFunction: timingFunction,
                     fromState: fromState,
                     removeOnComplete: removeOnComplete,
                     onComplete: onComplete)
    }
    
    public func popOut(duration: TimeInterval, delay: TimeInterval? = nil, timingFunction: CAMediaTimingFunction = .easeInCubic, fromState: FromState = .auto, removeOnComplete: Bool = true, onComplete: ((_ flag: Bool) -> Void)? = nil) {
        self.animate(from: NSNumber(value: 1.0) as NSValue,
                     to: NSNumber(value: 0.0) as NSValue,
                     keyPath: "transform.scale",
                     duration: duration,
                     delay: delay,
                     timingFunction: timingFunction,
                     fromState: fromState,
                     removeOnComplete: removeOnComplete,
                     onComplete: onComplete)
    }
    
    public func slideX(from: CGFloat, to: CGFloat, duration: TimeInterval, delay: TimeInterval? = nil, timingFunction: CAMediaTimingFunction? = nil, fromState: FromState = .auto, removeOnComplete: Bool = true, onComplete: ((_ flag: Bool) -> Void)? = nil) {
        self.animate(from: NSNumber(value: from) as NSValue,
                     to: NSNumber(value: to) as NSValue,
                     keyPath: "transform.translation.x",
                     duration: duration,
                     delay: delay,
                     timingFunction: timingFunction,
                     fromState: fromState,
                     removeOnComplete: removeOnComplete,
                     onComplete: onComplete)
    }
    
    public func slideY(from: CGFloat, to: CGFloat, duration: TimeInterval, delay: TimeInterval? = nil, timingFunction: CAMediaTimingFunction? = nil, fromState: FromState = .auto, removeOnComplete: Bool = true, onComplete: ((_ flag: Bool) -> Void)? = nil) {
        self.animate(from: NSNumber(value: from) as NSValue,
                     to: NSNumber(value: to) as NSValue,
                     keyPath: "transform.translation.y",
                     duration: duration,
                     delay: delay,
                     timingFunction: timingFunction,
                     fromState: fromState,
                     removeOnComplete: removeOnComplete,
                     onComplete: onComplete)
    }
    
    public func fadeIn(duration: TimeInterval, delay: TimeInterval? = nil, fromState: FromState = .auto, removeOnComplete: Bool = true, onComplete: ((_ flag: Bool) -> Void)? = nil) {
        self.animate(from: NSNumber(value: 0.0) as NSValue,
                     to: NSNumber(value: 1.0) as NSValue,
                     keyPath: "opacity",
                     duration: duration,
                     delay: delay,
                     fromState: fromState,
                     removeOnComplete: removeOnComplete,
                     onComplete: onComplete
        )
    }
    
    public func fadeOut(duration: TimeInterval, delay: TimeInterval? = nil, fromState: FromState = .auto, removeOnComplete: Bool = true, onComplete: ((_ flag: Bool) -> Void)? = nil) {
        self.animate(from: NSNumber(value: 1.0) as NSValue,
                     to: NSNumber(value: 0.0) as NSValue,
                     keyPath: "opacity",
                     duration: duration,
                     delay: delay,
                     fromState: fromState,
                     removeOnComplete: removeOnComplete,
                     onComplete: onComplete
        )
    }
}

extension CAMediaTimingFunction {
    // to watch easing graphics, visit: https://easings.net/
    
    // linear
    public static let linear: CAMediaTimingFunction = CAMediaTimingFunction(name: .linear)
    
    // ease sine
    public static let easeInSine: CAMediaTimingFunction = .init(controlPoints: 0.12, 0, 0.39, 0)
    public static let easeOutSine: CAMediaTimingFunction = .init(controlPoints: 0.61, 1, 0.88, 1)
    public static let easeInOutSine: CAMediaTimingFunction = .init(controlPoints: 0.37, 0, 0.63, 1)
    
    // ease quad
    public static let easeInQuad: CAMediaTimingFunction = .init(controlPoints: 0.11, 0, 0.5, 0)
    public static let easeOutQuad: CAMediaTimingFunction = .init(controlPoints: 0.5, 1, 0.89, 1)
    public static let easeInOutQuad: CAMediaTimingFunction = .init(controlPoints: 0.45, 0, 0.55, 1)
    
    // ease cubic
    public static let easeInCubic: CAMediaTimingFunction = .init(controlPoints: 0.32, 0, 0.67, 0)
    public static let easeOutCubic: CAMediaTimingFunction = .init(controlPoints: 0.33, 1, 0.68, 1)
    public static let easeInOutCubic: CAMediaTimingFunction = .init(controlPoints: 0.65, 0, 0.35, 1)
    
    // ease quart
    public static let easeInQuart: CAMediaTimingFunction = .init(controlPoints: 0.5, 0, 0.75, 0)
    public static let easeOutQuart: CAMediaTimingFunction = .init(controlPoints: 0.25, 1, 0.5, 1)
    public static let easeInOutQuart: CAMediaTimingFunction = .init(controlPoints: 0.76, 0, 0.24, 1)
    
    // ease quint
    public static let easeInQuint: CAMediaTimingFunction = .init(controlPoints: 0.64, 0, 0.78, 0)
    public static let easeOutQuint: CAMediaTimingFunction = .init(controlPoints: 0.22, 1, 0.36, 1)
    public static let easeInOutQuint: CAMediaTimingFunction = .init(controlPoints: 0.83, 0, 0.17, 1)
    
    // ease expo
    public static let easeInExpo: CAMediaTimingFunction = .init(controlPoints: 0.7, 0, 0.84, 0)
    public static let easeOutExpo: CAMediaTimingFunction = .init(controlPoints: 0.16, 1, 0.3, 1)
    public static let easeInOutExpo: CAMediaTimingFunction = .init(controlPoints: 0.87, 0, 0.13, 1)
    
    // ease circ
    public static let easeInCirc: CAMediaTimingFunction = .init(controlPoints: 0.55, 0, 1, 0.45)
    public static let easeOutCirc: CAMediaTimingFunction = .init(controlPoints: 0, 0.55, 0.45, 1)
    public static let easeInOutCirc: CAMediaTimingFunction = .init(controlPoints: 0.85, 0, 0.15, 1)
    
    // ease back
    public static let easeInBack: CAMediaTimingFunction = .init(controlPoints: 0.36, 0, 0.66, -0.56)
    public static let easeOutBack: CAMediaTimingFunction = .init(controlPoints: 0.34, 1.56, 0.64, 1)
    public static let easeInOutBack: CAMediaTimingFunction = .init(controlPoints: 0.68, -0.6, 0.32, 1.6)
}
