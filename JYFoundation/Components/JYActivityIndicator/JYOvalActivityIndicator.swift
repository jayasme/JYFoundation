//
//  JYActivityIndicator.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/6.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit


public class JYOvalActivityIndicator : UIView, IActivityIndicator {
    
    private var dotView1 : UIView!
    private var dotView2 : UIView!
    private var dotView3 : UIView!
    
    private let animationDuration: TimeInterval = 0.1
    private let dotWidth: CGFloat = 6
    
    // MARK: Properties
    
    public override var tintColor: UIColor! {
        didSet {
            if dotView1 != nil {
                dotView1.backgroundColor = tintColor
            }
            if dotView2 != nil {
                dotView2.backgroundColor = tintColor
            }
            if dotView3 != nil {
                dotView3.backgroundColor = tintColor
            }
        }
    }
    
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
        tintColor = UIColor.black
        
        dotView1 = UIView()
        dotView1.backgroundColor = tintColor
        addSubview(dotView1)
        
        dotView2 = UIView()
        dotView2.backgroundColor = tintColor
        addSubview(dotView2)
        
        dotView3 = UIView()
        dotView3.backgroundColor = tintColor
        addSubview(dotView3)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        guard dotView1 != nil && dotView2 != nil && dotView3 != nil else { return }
        
        let widthUnit = bounds.width / 6
        let centerY = bounds.height / 2 - dotWidth / 2
        
        dotView1.frame = CGRect(x: widthUnit - dotWidth / 2, y: centerY, width: dotWidth, height: dotWidth)
        dotView2.frame = CGRect(x: widthUnit * 3 - dotWidth / 2, y: centerY, width: dotWidth, height: dotWidth)
        dotView3.frame = CGRect(x: widthUnit * 5 - dotWidth / 2, y: centerY, width: dotWidth, height: dotWidth)
        
        dotView1.layer.cornerRadius = dotWidth / 2
        dotView1.clipsToBounds = true
        dotView2.layer.cornerRadius = dotWidth / 2
        dotView2.clipsToBounds = true
        dotView3.layer.cornerRadius = dotWidth / 2
        dotView3.clipsToBounds = true
    }
    
    
    
    
    
    // MARK: Publics
    
    public func startAnimation() {
        guard dotView1 != nil && dotView2 != nil && dotView3 != nil else { return }
        
        isAnimating = true
        dotView1.alpha = 1
        dotView2.alpha = 1
        dotView3.alpha = 1
        dotView1.isVisible = true
        dotView2.isVisible = true
        dotView3.isVisible = true

        UIView.animate(withDuration: self.animationDuration, animations: {
            self.dotView1.alpha = 0.2
        }) { (finished1) in
            guard finished1 && self.isAnimating else { return }

           UIView.animate(withDuration: self.animationDuration, animations: {
                self.dotView1.alpha = 1
                self.dotView2.alpha = 0.2
            }, completion: { (finished2) in
                guard finished2 && self.isAnimating else { return }
                
                UIView.animate(withDuration: self.animationDuration, animations: {
                    self.dotView2.alpha = 1
                    self.dotView3.alpha = 0.2
                    
                }, completion: { (finished3) in
                    guard finished3 && self.isAnimating else { return }
                    
                    UIView.animate(withDuration: self.animationDuration, animations: { 
                        self.dotView3.alpha = 1
                    }, completion: { (finished4) in
                        guard finished4 && self.isAnimating else { return }

                        self.startAnimation()
                    })
                })
            })
        }
    }
    
    public func stopAnimation() {
        isAnimating = false
        
        dotView1.isVisible = false
        dotView2.isVisible = false
        dotView3.isVisible = false
    }
}
