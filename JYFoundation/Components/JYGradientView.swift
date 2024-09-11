//
//  JYGradientView.swift
//  JYFoundation
//
//  Created by 荣超 on 2022/5/28.
//  Copyright © 2022 jayasme. All rights reserved.
//

import Foundation
import UIKit

public class JYGradientView: UIView {
    
    private weak var gradientLayer: CALayer? = nil
    
    public struct GradientPoint {
        public let location: CGFloat
        public let color: UIColor
        
        public init(location: CGFloat, color: UIColor) {
            self.location = location
            self.color = color
        }
    }
    
    public enum Gradient {
        case linear(startPoint: CGPoint, endPoint: CGPoint, gradients: [GradientPoint])
        case radial(centerPoint: CGPoint, radiusX: CGFloat, radiusY: CGFloat, rotation: CGFloat, gradients: [GradientPoint])
    }
        
    public var gradient: Gradient? = nil {
        didSet {
            if self.gradient != nil {
                self.gradientLayer?.removeFromSuperlayer()
                self.gradientLayer = nil
            }
            
            guard let gradient = self.gradient else {
                return
            }
            
            switch(gradient) {
            case .linear(let startPoint, let endPoint, let gradients):
                do {
                    let layer = CAGradientLayer()
                    layer.startPoint = startPoint
                    layer.endPoint = endPoint
                    layer.colors = gradients.map { $0.color.cgColor }
                    layer.locations = gradients.map { NSNumber(value: Float($0.location)) }
                    layer.frame = self.bounds
                    self.layer.insertSublayer(layer, at: 0)
                    self.gradientLayer = layer
                    break
                }
            case .radial(let centerPoint, let radiusX, let radiusY, let rotation, let gradients):
                do {
                    let layer = RadialGradientLayer(gradients: gradients,
                                                    centerPoint: centerPoint,
                                                    radiusX: radiusX,
                                                    radiusY: radiusY,
                                                    rotation: rotation
                    )
                    layer.frame = self.bounds
                    self.layer.insertSublayer(layer, at: 0)
                    self.gradientLayer = layer
                    break
                }
            }
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        self.gradientLayer?.frame = self.bounds
    }
}

private class LinearGradientLayer: CALayer {
    
    var gradients: [JYGradientView.GradientPoint]?
    var startPoint: CGPoint?
    var endPoint: CGPoint?
    
    init(gradients: [JYGradientView.GradientPoint], startPoint: CGPoint, endPoint: CGPoint) {
        self.gradients = gradients
        self.startPoint = startPoint
        self.endPoint = endPoint
        super.init()
        self.needsDisplayOnBoundsChange = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    override func draw(in ctx: CGContext) {
        guard
            let gradients = self.gradients,
            let startPoint = self.startPoint,
            let endPoint = self.endPoint
        else {
            return
        }
        
        ctx.saveGState()

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations = gradients.map{ $0.location }
        let colors = gradients.map { $0.color.cgColor } as CFArray
        guard let gradient = CGGradient(colorsSpace: colorSpace,
                                        colors: colors,
                                        locations: locations)
        else {
            ctx.restoreGState()
            return
        }
        
        let sp = CGPoint(x: startPoint.x * self.bounds.width, y: startPoint.y * self.bounds.height)
        let ep = CGPoint(x: endPoint.x * self.bounds.width, y: endPoint.y * self.bounds.height)
        ctx.drawLinearGradient(gradient,
                               start: sp,
                               end: ep,
                               options: .drawsBeforeStartLocation)
        ctx.restoreGState()
    }
}


private class RadialGradientLayer: CALayer {
    
    var gradients: [JYGradientView.GradientPoint]?
    var centerPoint: CGPoint?
    var radiusX: CGFloat?
    var radiusY: CGFloat?
    var rotation: CGFloat?
    
    init(gradients: [JYGradientView.GradientPoint], centerPoint: CGPoint, radiusX: CGFloat, radiusY: CGFloat, rotation: CGFloat) {
        self.gradients = gradients
        self.centerPoint = centerPoint
        self.radiusX = radiusX
        self.radiusY = radiusY
        self.rotation = rotation
        super.init()
        self.needsDisplayOnBoundsChange = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    override func draw(in ctx: CGContext) {
        guard
            let gradients = gradients,
            let centerPoint = centerPoint,
            let radiusX = radiusX,
            let radiusY = radiusY,
            let rotation = rotation,
            radiusX > 0 && radiusY > 0
        else {
            return
        }
        
        ctx.saveGState()

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations = gradients.map{ $0.location }
        let colors = gradients.map { $0.color.cgColor } as CFArray
        guard let gradient = CGGradient(colorsSpace: colorSpace,
                                        colors: colors,
                                        locations: locations)
        else {
            ctx.restoreGState()
            return
        }
        
        let rx = radiusX * self.bounds.width
        let ry = radiusY * self.bounds.height
        let cp = CGPoint(x: centerPoint.x * self.bounds.width, y: centerPoint.y * self.bounds.height)
        let r = max(rx, ry)
        
        if (rx > ry) {
            ctx.translateBy(x: cp.x - (cp.x * (rx / ry)), y: 0)
            ctx.scaleBy(x: rx / ry, y: 1)
        } else {
            ctx.translateBy(x: 0, y: cp.y - (cp.y * (ry / rx)))
            ctx.scaleBy(x: 1, y: ry / rx)
        }
        ctx.rotate(by: rotation)
        
        ctx.drawRadialGradient(gradient,
                               startCenter: cp,
                               startRadius: r,
                               endCenter: cp,
                               endRadius: 0,
                               options: .drawsBeforeStartLocation
        )
        ctx.restoreGState()
    }
}
