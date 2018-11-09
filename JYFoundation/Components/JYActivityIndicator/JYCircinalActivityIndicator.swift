//
//  JYCircinalActivityIndicator.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/26.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation


public class JYCircinalActivityIndicator: UIView, IActivityIndicator {
    
    private let animationDuration: TimeInterval = 1.2
    private let FPS: TimeInterval = 60

    private var _timer: Timer? = nil
    private var timeInterval1: TimeInterval = 0
    private var timeInterval2: TimeInterval = 0
    
    // MARK: Properties
    
    internal(set) public var isAnimating : Bool = false
    
    // MARK: Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializer()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializer()
    }
    
    func initializer() {
        backgroundColor = UIColor.clear
        tintColor = UIColor(white: 0, alpha: 0.2)
    }
    
    // MARK: Publics
    
    public func startAnimation() {
        guard !isAnimating else {
            return
        }
        isAnimating = true
        timeInterval1 = 0
        timeInterval2 = animationDuration / 2
        
        _timer = Timer.scheduledTimer(timeInterval: 1 / FPS, target: self, selector: #selector(timer), userInfo: nil, repeats: true)
    }
    
    @objc private func timer() {
        setNeedsDisplay()
        
        timeInterval1 += 1 / FPS
        timeInterval2 += 1 / FPS
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext(), isAnimating else {
            return
        }
        
        let scale1 = CGFloat(cos(timeInterval1 * Double.pi * 2 / animationDuration)) / 2 + 0.5
        let scale2 = CGFloat(cos(timeInterval2 * Double.pi * 2 / animationDuration)) / 2 + 0.5
        
        context.setFillColor(tintColor.cgColor)
        context.fillEllipse(in: CGRect(x: rect.midX - scale1 * rect.midX,
                                       y: rect.midY - scale1 * rect.midY,
                                       width: scale1 * rect.width,
                                       height: scale1 * rect.height))
        context.fillEllipse(in: CGRect(x: rect.midX - scale2 * rect.midX,
                                       y: rect.midY - scale2 * rect.midY,
                                       width: scale2 * rect.width,
                                       height: scale2 * rect.height))
    }
    
    public func stopAnimation() {
        isAnimating = false
        _timer?.invalidate()
        _timer = nil
        setNeedsDisplay()
    }
    
}
