//
//  JYGestureView.swift
//  JYFoundation
//
//  Created by 荣超 on 2022/2/7.
//  Copyright © 2022 jayasme. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol JYGestureViewDelegate: AnyObject {
    @objc optional func onPanStart(direction: JYGestureView.PanDirection, startLocation: CGPoint)
    @objc optional func onPanHorizontally(offset: CGFloat)
    @objc optional func onPanVertically(offset: CGFloat)
    @objc optional func onPanEnd(direction: JYGestureView.PanDirection, offset: CGFloat, velocity: CGFloat)
    @objc optional func onTap(location: CGPoint)
    @objc optional func onDoubleTap(location: CGPoint)
    @objc optional func onLongPress(location: CGPoint)
}

public class JYGestureView: UIView {
    
    @objc public enum PanDirection: Int {
        case left = 0
        case right = 1
        case top = 2
        case bottom = 3
        
        var horizontal: Bool {
            return self == .left || self == .right
        }
        
        var vertical: Bool {
            return self == .top || self == .bottom
        }
    }

    private var panGesture: UIPanGestureRecognizer!
    private var tapGesture: UITapGestureRecognizer!
    private var doubleTapGesture: UITapGestureRecognizer!
    private var longPressGesture: UILongPressGestureRecognizer!
    
    private var startLocation: CGPoint? = nil
    
    private var panDirection: PanDirection? = nil
    private var panStartedTriggered: Bool = false
    
    public weak var delegate: JYGestureViewDelegate? = nil
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(sender:)))
        self.addGestureRecognizer(self.panGesture)
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(sender:)))
        self.addGestureRecognizer(self.tapGesture)
        self.doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(sender:)))
        self.doubleTapGesture.numberOfTapsRequired = 2
        self.addGestureRecognizer(self.doubleTapGesture)
        self.longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(sender:)))
        self.addGestureRecognizer(self.longPressGesture)
    }
    
    deinit {
        self.removeGestureRecognizer(self.panGesture)
        self.removeGestureRecognizer(self.tapGesture)
        self.removeGestureRecognizer(self.doubleTapGesture)
        self.removeGestureRecognizer(self.longPressGesture)
    }
    
    @objc func handlePanGesture(sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            self.startLocation = sender.location(in: self)
        }
        if sender.state == .changed, let startLocation = self.startLocation {
            let translation = sender.translation(in: self)
            let x = translation.x
            let y = translation.y
            if let panDirection = self.panDirection {
                if panDirection.horizontal {
                    self.delegate?.onPanHorizontally?(offset: x)
                } else {
                    self.delegate?.onPanVertically?(offset: y)
                }
            } else if abs(x) >= 10 || abs(y) >= 10 {
                self.panDirection = abs(x) > abs(y) ? (x < 0 ? PanDirection.left : PanDirection.right) : (y < 0 ? PanDirection.top : PanDirection.bottom)
                if (!panStartedTriggered) {
                    self.panStartedTriggered = true
                    if self.panDirection!.horizontal {
                        self.delegate?.onPanStart?(direction: panDirection!, startLocation: startLocation)
                    } else {
                        self.delegate?.onPanStart?(direction: panDirection!, startLocation: startLocation)
                    }
                }
            }
        }
        if sender.state == .ended || sender.state == .failed || sender.state == .cancelled {
            let translation = sender.translation(in: self)
            let x = translation.x
            let y = translation.y
            let velocity = sender.velocity(in: self)
            if let panDirection = self.panDirection {
                if panDirection.horizontal {
                    self.delegate?.onPanEnd?(direction: panDirection, offset: x, velocity: velocity.x)
                } else {
                    self.delegate?.onPanEnd?(direction: panDirection, offset: y, velocity: velocity.y)
                }
            }
            self.startLocation = nil
            self.panDirection = nil
            self.panStartedTriggered = false
        }
    }
    
    @objc func handleTapGesture(sender: UITapGestureRecognizer) {
        guard sender.state == .ended else {
            return
        }
        let location = sender.location(in: self)
        self.delegate?.onTap?(location: location)
    }
    
    @objc func handleDoubleTapGesture(sender: UITapGestureRecognizer) {
        guard sender.state == .ended else {
            return
        }
        let location = sender.location(in: self)
        self.delegate?.onDoubleTap?(location: location)
    }
    
    @objc func handleLongPressGesture(sender: UILongPressGestureRecognizer) {
        let location = sender.location(in: self)
        self.delegate?.onLongPress?(location: location)
    }
}
