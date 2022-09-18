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
    
    private var animated: Bool = false
    
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
    
    private func animateIn() {
        self.animated = true
        
        switch (self.feedbackType) {
        case .none:
            // do nothing
            break
        case let .opacity(value):
            self.alpha = 1
            UIView.animate(withDuration: self.duration,
                           delay: 0,
                           options: [.beginFromCurrentState, .curveEaseOut],
                           animations: {
                            self.alpha = value
            }, completion: nil)
            break
        case let .scale(value):
            self.transform = CGAffineTransform(scaleX: 1, y: 1)
            UIView.animate(withDuration: self.duration,
                           delay: 0,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 1,
                           options: [.beginFromCurrentState, .curveEaseOut],
                           animations: {
                            self.transform = CGAffineTransform(scaleX: value, y: value)
            }, completion: nil)
            break
        case .highlight(_):
            guard let backView = self.backView else {
                break
            }
            backView.alpha = 0
            UIView.animate(withDuration: self.duration,
                           delay: 0,
                           options: [.beginFromCurrentState, .curveEaseOut],
                           animations: {
                            backView.alpha = 1
            }, completion: nil)
            break
        }
    }
    
    private func animateOut() {
        guard self.animated else {
            return
        }
        
        self.animated = false
        switch (self.feedbackType) {
        case .none:
            // do nothing
            break
        case let .opacity(value):
            self.alpha = value
            UIView.animate(withDuration: self.duration,
                           delay: 0,
                           options: [.beginFromCurrentState, .curveEaseOut],
                           animations: {
                            self.alpha = 1
            }, completion: nil)
            break
        case let .scale(value):
            self.transform = CGAffineTransform(scaleX: value, y: value)
            UIView.animate(withDuration: self.duration,
                           delay: 0,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 1,
                           options: [.beginFromCurrentState, .curveEaseOut],
                           animations: {
                            self.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: nil)
            break
        case .highlight(_):
            guard let backView = self.backView else {
                break
            }
            backView.alpha = 1
            UIView.animate(withDuration: self.duration,
                           delay: 0,
                           options: [.beginFromCurrentState, .curveEaseOut],
                           animations: {
                            backView.alpha = 0
            }, completion: nil)
            break
        }
    }
}
