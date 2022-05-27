//
//  JYGradientView.swift
//  JYFoundation
//
//  Created by 荣超 on 2022/5/28.
//  Copyright © 2022 jayasme. All rights reserved.
//

import Foundation
import UIKit

public class GradientView: UIView {
    
    private weak var gradientLayer: CALayer? = nil
    
    public struct GradientPoint {
        public let location: CGFloat
        public let color: UIColor
    }
    
    public enum Gradient {
        case linear(startPoint: CGPoint, endPoint: CGPoint, gradients: [GradientPoint])
        case radial(centerPoint: CGPoint, radiusX: CGFloat, radiusY: CGFloat, rotation: CGFloat, gradients: [GradientPoint])
    }
        
    public var gradient: Gradient? = nil {
        didSet {
            guard let gradient = self.gradient else {
                if let gradientLayer = self.gradientLayer {
                    gradientLayer.removeFromSuperlayer()
                    self.gradientLayer = nil
                }
                return
            }
            
            switch(gradient) {
            case .linear(let startPoint, let endPoint, let gradients):
                do {
                    let layer = LinearGradientLayer(gradients: gradients, startPoint: startPoint, endPoint: endPoint)
                    layer.bounds = self.bounds
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
                    layer.bounds = self.bounds
                    self.layer.insertSublayer(layer, at: 0)
                    self.gradientLayer = layer
                    break
                }
            }
        }
    }
    
    public override func layoutSublayers(of layer: CALayer) {
        guard let gradientLayer = self.gradientLayer else {
            return
        }

        gradientLayer.frame = self.bounds
    }
}

private class LinearGradientLayer: CALayer {
    
    var gradients: [GradientView.GradientPoint]
    var startPoint: CGPoint
    var endPoint: CGPoint
    
    init(gradients: [GradientView.GradientPoint], startPoint: CGPoint, endPoint: CGPoint) {
        self.gradients = gradients
        self.startPoint = startPoint
        self.endPoint = endPoint
        super.init()
        self.needsDisplayOnBoundsChange = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(in ctx: CGContext) {
        ctx.saveGState()

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations = gradients.map{ $0.location }
        let colors = gradients.map { $0.color.cgColor } as CFArray
        guard let gradient = CGGradient(colorsSpace: colorSpace,
                                        colors: colors,
                                        locations: locations)
        else {
            return
        }
        
        let startPoint = CGPoint(x: self.startPoint.x * self.bounds.width, y: self.startPoint.y * self.bounds.height)
        let endPoint = CGPoint(x: self.endPoint.x * self.bounds.width, y: self.endPoint.y * self.bounds.height)
        ctx.drawLinearGradient(gradient,
                               start: startPoint,
                               end: endPoint,
                               options: .drawsBeforeStartLocation)
        ctx.restoreGState()
    }
}


private class RadialGradientLayer: CALayer {
    
    var gradients: [GradientView.GradientPoint]
    var centerPoint: CGPoint
    var radiusX: CGFloat
    var radiusY: CGFloat
    var rotation: CGFloat
    
    init(gradients: [GradientView.GradientPoint], centerPoint: CGPoint, radiusX: CGFloat, radiusY: CGFloat, rotation: CGFloat) {
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
    
    override func draw(in ctx: CGContext) {
        ctx.saveGState()

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations = gradients.map{ $0.location }
        let colors = gradients.map { $0.color.cgColor } as CFArray
        guard let gradient = CGGradient(colorsSpace: colorSpace,
                                        colors: colors,
                                        locations: locations),
              self.radiusX > 0 && self.radiusY > 0
        else {
            return
        }
        
        let radiusX = self.radiusX * self.bounds.width
        let radiusY = self.radiusY * self.bounds.height
        let centerPoint = CGPoint(x: self.centerPoint.x * self.bounds.width, y: self.centerPoint.y * self.bounds.height)
        let radius = max(radiusX, radiusY)
        
        if (radiusX > radiusY) {
            ctx.translateBy(x: centerPoint.x - (centerPoint.x * (radiusX / radiusY)), y: 0)
            ctx.scaleBy(x: radiusX / radiusY, y: 1)
        } else {
            ctx.translateBy(x: 0, y: centerPoint.y - (centerPoint.y * (radiusY / radiusX)))
            ctx.scaleBy(x: 1, y: radiusY / radiusX)
        }
        ctx.rotate(by: rotation)
        
        ctx.drawRadialGradient(gradient,
                               startCenter: centerPoint,
                               startRadius: radius,
                               endCenter: centerPoint,
                               endRadius: 0,
                               options: .drawsBeforeStartLocation
        )
        ctx.restoreGState()
    }
}
