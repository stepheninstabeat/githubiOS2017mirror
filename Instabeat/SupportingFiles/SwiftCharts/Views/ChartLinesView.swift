//
//  ChartLinesView.swift
//  swift_charts
//
//  Created by ischuetz on 11/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

public protocol ChartLinesViewPathGenerator {
    func generatePath(points points: [CGPoint], lineWidth: CGFloat) -> UIBezierPath
}

public class ChartLinesView: UIView {

    private let lineColors: [UIColor]
    private let lineWidth: CGFloat
    private let positions: [CGFloat]
    private let animDuration: Float
    private let animDelay: Float

    init(path: UIBezierPath,
         frame: CGRect,
         lineColors: [UIColor],
         positions: [CGFloat],
         lineWidth: CGFloat,
         animDuration: Float,
         animDelay: Float) {
        
        self.lineColors = lineColors
        self.positions = positions
        self.lineWidth = lineWidth
        self.animDuration = animDuration
        self.animDelay = animDelay
        
        super.init(frame: frame)

        self.backgroundColor = UIColor.clearColor()
        self.show(path: path)
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLineMask(frame frame: CGRect) -> CALayer {
        let lineMaskLayer = CAShapeLayer()
        var maskRect = frame
        maskRect.origin.y = 0
        maskRect.size.height = frame.size.height
        let path = CGPathCreateWithRect(maskRect, nil)
        
        lineMaskLayer.path = path
        
        return lineMaskLayer
    }

    private func generateLayer(path path: UIBezierPath) -> CAShapeLayer {
        let lineLayer = CAShapeLayer()

        lineLayer.path = path.CGPath
//        lineLayer.lineJoin = kCALineJoinBevel
        lineLayer.lineWidth   = self.lineWidth
//        lineLayer.strokeColor = UIColor.grayColor().CGColor
      
        CATransaction.begin()
        CATransaction.setAnimationDuration(Double(self.animDuration))
        for i in 0..<positions.count {
            let strokePart = CAShapeLayer()
            strokePart.path = lineLayer.path
            strokePart.lineWidth = lineWidth
            strokePart.strokeStart = positions[i]
            if i == (positions.count - 1) {
                strokePart.strokeEnd = 1.0
            }
            else {
                strokePart.strokeEnd = positions[i + 1]
            }
            print(strokePart.strokeStart, strokePart.strokeEnd)
            strokePart.strokeColor = lineColors[i].CGColor
            lineLayer.addSublayer(strokePart)
            
            let pathAnimation = CAKeyframeAnimation(keyPath: "strokeEnd")
            let times = [0.0, // Note: This works because both the times and the stroke start/end are on scales of 0..1
                strokePart.strokeStart,
                strokePart.strokeEnd,
                1.0]
            let values = [strokePart.strokeStart,
                          strokePart.strokeStart,
                          strokePart.strokeEnd,
                          strokePart.strokeEnd]
            
            pathAnimation.keyTimes = times
            pathAnimation.values = values
            pathAnimation.removedOnCompletion = false
            pathAnimation.fillMode = kCAFillModeForwards
            strokePart.addAnimation(pathAnimation, forKey: "strokeEndAnimation")
        }
        
        
//        for i in 0..<positions.count {
//            var sum: CGFloat = 0
//            if i > 0 {
//                let subArray = positions[0...i - 1]
//                sum = subArray.reduce(0, combine: +)
//            }
//            let strokePart = CAShapeLayer()
//            strokePart.path = lineLayer.path
//            
//            strokePart.lineWidth = lineWidth
//            
//            strokePart.strokeStart = sum
//            if i == positions.count {
//                strokePart.strokeEnd = 1.0
//            }
//            else {
//                strokePart.strokeEnd = sum + positions[i]
//            }
//            print(strokePart.strokeStart, strokePart.strokeEnd)
//            strokePart.strokeColor = lineColors[i].CGColor
//            lineLayer.addSublayer(strokePart)
//            
//            let pathAnimation = CAKeyframeAnimation(keyPath: "strokeEnd")
//            let times = [0.0, // Note: This works because both the times and the stroke start/end are on scales of 0..1
//                strokePart.strokeStart,
//                strokePart.strokeEnd,
//                1.0]
//            let values = [strokePart.strokeStart,
//                          strokePart.strokeStart,
//                          strokePart.strokeEnd,
//                          strokePart.strokeEnd]
//            
//            pathAnimation.keyTimes = times
//            pathAnimation.values = values
//            pathAnimation.removedOnCompletion = false
//            pathAnimation.fillMode = kCAFillModeForwards
//            strokePart.addAnimation(pathAnimation, forKey: "strokeEndAnimation")
//        }
//        
        CATransaction.commit()
        return lineLayer
    }
    
    private func show(path path: UIBezierPath) {
        let lineMask = self.createLineMask(frame: frame)
        self.layer.mask = lineMask
        self.layer.addSublayer(self.generateLayer(path: path))
    }
 }
