//
//  JYFeedbackButton.swift
//  JYFoundation
//
//  Created by 荣超 on 2022/8/29.
//  Copyright © 2022 jayasme. All rights reserved.
//

import Foundation
import UIKit

public class JYFeedbackButton: UIButton {
    
    public enum FeedbackType {
        case none
        case highlight(value: UIColor)
        case opacity(value: CGFloat = 0.5)
        case scale(value: CGFloat = 0.9)
    }
    
    public private(set) var feedbackType: FeedbackType = .none
    
    private let animationKey = "JYFeedbackButton"
    
    public var duration: TimeInterval = 0.2
    
    public convenience init(frame: CGRect = .zero, feedbackType: FeedbackType) {
        self.init(frame: frame)
        self.feedbackType = feedbackType
        self.isUserInteractionEnabled = true
        
        if case .highlight(let color) = feedbackType {
            let backView = UIView()
            backView.backgroundColor = color
            backView.frame = frame
            backView.alpha = 0
            self.addSubview(backView)
            self.backView = backView
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // make sure the backView is always on bottom
    public override func insertSubview(_ view: UIView, at index: Int) {
        super.insertSubview(view, at: index)
        
        if let backView = self.backView, index == 0 {
            self.insertSubview(backView, at: 0)
        }
    }
    
    // make sure the backView is always fullfilled
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.backView?.frame = self.bounds
    }
    
    private var backView: UIView? = nil
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.animateIn()
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.animateOut()
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.animateOut()
    }
    
    private var animation: CABasicAnimation? = nil
    
    private func animateIn() {
        self.stopAnimation()
        
        switch (self.feedbackType) {
        case .none:
            // do nothing
            break
        case let .opacity(value):
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = NSNumber(value: 1)
            animation.toValue = NSNumber(value: value)
            animation.duration = self.duration
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            self.layer.add(animation, forKey: animationKey)
            self.animation = animation
            break
        case let .scale(value):
            let animation = CABasicAnimation(keyPath: "transform.scale")
            animation.fromValue = NSNumber(value: 1)
            animation.toValue = NSNumber(value: value)
            animation.duration = self.duration
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            self.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            self.layer.add(animation, forKey: animationKey)
            self.animation = animation
            break
        case .highlight(_):
            guard let backView = self.backView else {
                break
            }
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = NSNumber(value: 0)
            animation.toValue = NSNumber(value: 1)
            animation.duration = self.duration
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            backView.layer.add(animation, forKey: animationKey)
            self.animation = animation
            break
        }
    }
    
    private func animateOut() {
        self.stopAnimation()
        
        switch (self.feedbackType) {
        case .none:
            // do nothing
            break
        case let .opacity(value):
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = NSNumber(value: value)
            animation.toValue = NSNumber(value: 1)
            animation.duration = self.duration
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            self.layer.add(animation, forKey: animationKey)
            self.animation = animation
            break
        case let .scale(value):
            let animation = CABasicAnimation(keyPath: "transform.scale")
            animation.fromValue = NSNumber(value: value)
            animation.toValue = NSNumber(value: 1)
            animation.duration = self.duration
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            self.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            self.layer.add(animation, forKey: animationKey)
            self.animation = animation
            break
        case .highlight(_):
            guard let backView = self.backView else {
                break
            }
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = NSNumber(value: 1)
            animation.toValue = NSNumber(value: 0)
            animation.duration = self.duration
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            backView.layer.add(animation, forKey: animationKey)
            self.animation = animation
            break
        }
    }
    
    private func stopAnimation() {
        self.layer.removeAnimation(forKey: animationKey)
        self.backView?.layer.removeAnimation(forKey: animationKey)
    }
}
