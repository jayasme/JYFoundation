//
//  UIView+JY.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/6.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit
import PromiseKit

extension UIView {
    
    /// 获取或设置View的可见度
    public var isVisible: Bool {
        get {
            return !isHidden
        }
        set(value) {
            isHidden = !value
        }
    }
    
    @discardableResult
    public func fadeIn(duration: TimeInterval = 0.3, delay: TimeInterval = 0) -> Promise<Void> {
        return Promise<Void> { seal in
            self.alpha = 0
            self.isVisible = true
            UIView.animate(withDuration: duration,
                           delay: delay,
                           options: .beginFromCurrentState,
                           animations: {
                            self.alpha = 1
            }) { (finished) in
                guard finished else { return }
                seal.fulfill(())
            }
        }
    }
    
    @discardableResult
    public func fadeOut(duration: TimeInterval = 0.3, delay: TimeInterval = 0) -> Promise<Void> {
        return Promise<Void> { seal in
            self.alpha = 1
            self.isVisible = true
            UIView.animate(withDuration: duration,
                           delay: delay,
                           options: .beginFromCurrentState,
                           animations: {
                            self.alpha = 0
            }) { (finished) in
                guard finished else { return }
                self.isVisible = false
                seal.fulfill(())
            }
        }
    }
    
    @discardableResult
    public func fade(to alpha: CGFloat, duration: TimeInterval = 0.3, delay: TimeInterval = 0) -> Promise<Void> {
        return Promise<Void> { seal in
            UIView.animate(withDuration: duration,
                           delay: delay,
                           options: .beginFromCurrentState,
                           animations: {
                            self.alpha = alpha
            }) { (finished) in
                guard finished else { return }
                seal.fulfill(())
            }
        }
    }
    
    @discardableResult
    public func popUp(duration: TimeInterval = 0.3, delay: TimeInterval = 0) -> Promise<Void> {
        return Promise<Void> { seal in
            self.transform = CGAffineTransform(scaleX: 0, y: 0)
            self.isVisible = true
            UIView.animate(withDuration: duration,
                           delay: delay,
                           usingSpringWithDamping: 0.6,
                           initialSpringVelocity: 1,
                           options: [.beginFromCurrentState, .curveEaseOut],
                           animations: { 
                            self.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: { (finished) in
                guard finished else { return }
                seal.fulfill(())
            })
        }
    }
    
    @discardableResult
    public func hideOff(duration: TimeInterval = 0.3, delay: TimeInterval = 0) -> Promise<Void> {
        return Promise<Void> { seal in
            self.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.isVisible = true
            UIView.animate(withDuration: duration,
                           delay: delay,
                           options: [.curveEaseOut],
                           animations: {
                            self.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            }) { (finished) in
                guard finished else { return }
                self.isVisible = false
                seal.fulfill(())
            }
        }
    }
    
}
