//
//  LineScatterCandleRadarChartRenderer.swift
//  Charts
//
//  Created by Daniel Cohen Gindi on 29/7/15.
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation
import CoreGraphics


public class LineScatterCandleRadarChartRenderer: ChartDataRendererBase
{
    public override init(animator: ChartAnimator?, viewPortHandler: ChartViewPortHandler)
    {
        super.init(animator: animator, viewPortHandler: viewPortHandler)
    }
    
    /// Draws vertical & horizontal highlight-lines if enabled.
    /// :param: context
    /// :param: points
    /// :param: horizontal
    /// :param: vertical
    public func drawHighlightLines(context: CGContext, point: CGPoint, set: ILineScatterCandleRadarChartDataSet)
    {
        //draw circle
        if set.isCircleHighlightIndicatorEnabled
        {
            context.beginPath()
            context.addArc(center: CGPoint(x: point.x, y: point.y), radius: 12, startAngle: 0.0, endAngle: CGFloat(M_PI * 2), clockwise: false)
            context.strokePath()
            return
        }
        // draw vertical highlight lines
        if set.isVerticalHighlightIndicatorEnabled
        {
            context.beginPath()
            context.move(to: CGPoint(x: point.x, y: point.y))
            context.addLine(to: CGPoint(x: point.x, y: 0))
            context.strokePath()
        }
        
        // draw horizontal highlight lines
        if set.isHorizontalHighlightIndicatorEnabled
        {
            context.beginPath()
            context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: point.y))
            context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: point.y))
            context.strokePath()
        }
        
        if set.isHigligtSelectedValueEnabled
        {
            context.beginPath()
            context.addArc(center: CGPoint(x: point.x, y: point.y), radius: 4, startAngle: 0.0, endAngle: CGFloat(M_PI * 2), clockwise: false)
            context.setFillColor(NSUIColor.white.cgColor)
            context.fillPath()
        }
    }
}
