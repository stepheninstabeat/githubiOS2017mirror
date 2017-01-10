//
//  ScatterChartRenderer.swift
//  Charts
//
//  Created by Daniel Cohen Gindi on 4/3/15.
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation
import CoreGraphics

#if !os(OSX)
    import UIKit
#endif


public class ScatterChartRenderer: LineScatterCandleRadarChartRenderer
{
    public weak var dataProvider: ScatterChartDataProvider?
    
    public init(dataProvider: ScatterChartDataProvider?, animator: ChartAnimator?, viewPortHandler: ChartViewPortHandler)
    {
        super.init(animator: animator, viewPortHandler: viewPortHandler)
        
        self.dataProvider = dataProvider
    }
    
    public override func drawData(context: CGContext)
    {
        guard let scatterData = dataProvider?.scatterData else { return }
        
        for i in 0 ..< scatterData.dataSetCount
        {
            guard let set = scatterData.getDataSetByIndex(index: i) else { continue }
            
            if set.isVisible
            {
                if !(set is IScatterChartDataSet)
                {
                    fatalError("Datasets for ScatterChartRenderer must conform to IScatterChartDataSet")
                }
                
                drawDataSet(context: context, dataSet: set as! IScatterChartDataSet)
            }
        }
    }
    
    private var _lineSegments = [CGPoint](repeating: CGPoint(), count: 2)
    
    public func drawDataSet(context: CGContext, dataSet: IScatterChartDataSet)
    {
        guard let
            dataProvider = dataProvider,
            let animator = animator
            else { return }
        
        let trans = dataProvider.getTransformer(which: dataSet.axisDependency)
        
        let phaseY = animator.phaseY
        
        let entryCount = dataSet.entryCount
        
        let shapeSize = dataSet.scatterShapeSize
        let shapeHalf = shapeSize / 2.0
        let shapeHoleSizeHalf = dataSet.scatterShapeHoleRadius
        let shapeHoleSize = shapeHoleSizeHalf * 2.0
        let shapeHoleColor = dataSet.scatterShapeHoleColor
        let shapeStrokeSize = (shapeSize - shapeHoleSize) / 2.0
        let shapeStrokeSizeHalf = shapeStrokeSize / 2.0
        
        var point = CGPoint()
        
        let valueToPixelMatrix = trans.valueToPixelMatrix
        
        let shape = dataSet.scatterShape
        
        context.saveGState()
        
        for j in 0 ..< Int(min(ceil(CGFloat(entryCount) * animator.phaseX), CGFloat(entryCount)))
        {
            guard let e = dataSet.entryForIndex(i: j) else { continue }
            
            point.x = CGFloat(e.xIndex)
            point.y = CGFloat(e.value) * phaseY
            point = point.applying(valueToPixelMatrix);
            
            if (!viewPortHandler.isInBoundsRight(x: point.x))
            {
                break
            }
            
            if (!viewPortHandler.isInBoundsLeft(x: point.x) || !viewPortHandler.isInBoundsY(y: point.y))
            {
                continue
            }
            
            if (shape == .Square)
            {
                if shapeHoleSize > 0.0
                {
                    context.setStrokeColor(dataSet.colorAt(index: j).cgColor)
                    context.setLineWidth(shapeStrokeSize)
                    var rect = CGRect()
                    rect.origin.x = point.x - shapeHoleSizeHalf - shapeStrokeSizeHalf
                    rect.origin.y = point.y - shapeHoleSizeHalf - shapeStrokeSizeHalf
                    rect.size.width = shapeHoleSize + shapeStrokeSize
                    rect.size.height = shapeHoleSize + shapeStrokeSize
                    context.stroke(rect)
                    
                    if let shapeHoleColor = shapeHoleColor
                    {
                        context.setFillColor(shapeHoleColor.cgColor)
                        rect.origin.x = point.x - shapeHoleSizeHalf
                        rect.origin.y = point.y - shapeHoleSizeHalf
                        rect.size.width = shapeHoleSize
                        rect.size.height = shapeHoleSize
                        context.fill(rect)
                    }
                }
                else
                {
                    context.setFillColor(dataSet.colorAt(index: j).cgColor)
                    var rect = CGRect()
                    rect.origin.x = point.x - shapeHalf
                    rect.origin.y = point.y - shapeHalf
                    rect.size.width = shapeSize
                    rect.size.height = shapeSize
                    context.fill(rect)
                }
            }
            else if (shape == .Circle)
            {
                if shapeHoleSize > 0.0
                {
                    context.setStrokeColor(dataSet.colorAt(index: j).cgColor)
                    context.setLineWidth(shapeStrokeSize)
                    var rect = CGRect()
                    rect.origin.x = point.x - shapeHoleSizeHalf - shapeStrokeSizeHalf
                    rect.origin.y = point.y - shapeHoleSizeHalf - shapeStrokeSizeHalf
                    rect.size.width = shapeHoleSize + shapeStrokeSize
                    rect.size.height = shapeHoleSize + shapeStrokeSize
                    context.strokeEllipse(in: rect)
                    
                    if let shapeHoleColor = shapeHoleColor
                    {
                        context.setFillColor(shapeHoleColor.cgColor)
                        rect.origin.x = point.x - shapeHoleSizeHalf
                        rect.origin.y = point.y - shapeHoleSizeHalf
                        rect.size.width = shapeHoleSize
                        rect.size.height = shapeHoleSize
                        context.fillEllipse(in: rect)
                    }
                }
                else
                {
                    context.setFillColor(dataSet.colorAt(index: j).cgColor)
                    var rect = CGRect()
                    rect.origin.x = point.x - shapeHalf
                    rect.origin.y = point.y - shapeHalf
                    rect.size.width = shapeSize
                    rect.size.height = shapeSize
                    context.fillEllipse(in: rect)
                }
            }
            else if (shape == .Triangle)
            {
                context.setFillColor(dataSet.colorAt(index: j).cgColor)
                
                // create a triangle path
                context.beginPath()
                context.move(to: CGPoint(x: point.x, y: point.y - shapeHalf))
                context.addLine(to: CGPoint(x: point.x + shapeHalf, y: point.y + shapeHalf))
                context.addLine(to: CGPoint(x: point.x - shapeHalf, y: point.y + shapeHalf))
                
                if shapeHoleSize > 0.0
                {
                    context.addLine(to: CGPoint(x: point.x , y: point.y - shapeHalf))
                    context.move(to: CGPoint(x: point.x - shapeHalf + shapeStrokeSize, y: point.y + shapeHalf - shapeStrokeSize))
                    context.addLine(to: CGPoint(x: point.x + shapeHalf - shapeStrokeSize, y: point.y + shapeHalf - shapeStrokeSize))
                    context.addLine(to: CGPoint(x: point.x, y: point.y - shapeHalf + shapeStrokeSize))
                    context.addLine(to: CGPoint(x: point.x - shapeHalf + shapeStrokeSize, y: point.y + shapeHalf - shapeStrokeSize))
                }
                
                context.closePath()
                
                context.fillPath()
                
                if shapeHoleSize > 0.0 && shapeHoleColor != nil
                {
                    context.setFillColor(shapeHoleColor!.cgColor)
                    
                    // create a triangle path
                    context.beginPath()
                    context.move(to: CGPoint(x: point.x, y: point.y - shapeHalf + shapeStrokeSize))
                    context.addLine(to: CGPoint(x: point.x + shapeHalf - shapeStrokeSize, y: point.y + shapeHalf - shapeStrokeSize))
                        context.addLine(to: CGPoint(x: point.x - shapeHalf + shapeStrokeSize, y: point.y + shapeHalf - shapeStrokeSize))
                            context.closePath()
                            
                            context.fillPath()
                }
            }
            else if (shape == .Cross)
            {
                context.setStrokeColor(dataSet.colorAt(index: j).cgColor)
                _lineSegments[0].x = point.x - shapeHalf
                _lineSegments[0].y = point.y
                _lineSegments[1].x = point.x + shapeHalf
                _lineSegments[1].y = point.y
                context.strokeLineSegments(between: _lineSegments)
                
                _lineSegments[0].x = point.x
                _lineSegments[0].y = point.y - shapeHalf
                _lineSegments[1].x = point.x
                _lineSegments[1].y = point.y + shapeHalf
                context.strokeLineSegments(between: _lineSegments)
            }
            else if (shape == .X)
            {
                context.setStrokeColor(dataSet.colorAt(index: j).cgColor)
                _lineSegments[0].x = point.x - shapeHalf
                _lineSegments[0].y = point.y - shapeHalf
                _lineSegments[1].x = point.x + shapeHalf
                _lineSegments[1].y = point.y + shapeHalf
                
                context.strokeLineSegments(between: _lineSegments)
                
                _lineSegments[0].x = point.x + shapeHalf
                _lineSegments[0].y = point.y - shapeHalf
                _lineSegments[1].x = point.x - shapeHalf
                _lineSegments[1].y = point.y + shapeHalf
                
                context.strokeLineSegments(between: _lineSegments)
            }
            else if (shape == .Custom)
            {
                context.setFillColor(dataSet.colorAt(index: j).cgColor)
                
                let customShape = dataSet.customScatterShape
                
                if customShape == nil
                {
                    return
                }
                
                // transform the provided custom path
                context.saveGState()
                context.translateBy(x: point.x, y: point.y)
                
                context.beginPath()
                context.addPath(customShape!)
                context.fillPath()
                
                context.restoreGState()
            }
        }
        
        context.restoreGState()
    }
    
    public override func drawValues(context: CGContext)
    {
        guard let
            dataProvider = dataProvider,
            let scatterData = dataProvider.scatterData,
            let animator = animator
            else { return }
        
        // if values are drawn
        if (scatterData.yValCount < Int(ceil(CGFloat(dataProvider.maxVisibleValueCount) * viewPortHandler.scaleX)))
        {
            guard let dataSets = scatterData.dataSets as? [IScatterChartDataSet] else { return }
            
            let phaseX = max(0.0, min(1.0, animator.phaseX))
            let phaseY = animator.phaseY
            
            var pt = CGPoint()
            
            for i in 0 ..< scatterData.dataSetCount
            {
                let dataSet = dataSets[i]
                
                if !dataSet.isDrawValuesEnabled || dataSet.entryCount == 0
                {
                    continue
                }
                
                let valueFont = dataSet.valueFont
                
                guard let formatter = dataSet.valueFormatter else { continue }
                
                let trans = dataProvider.getTransformer(which: dataSet.axisDependency)
                let valueToPixelMatrix = trans.valueToPixelMatrix
                
                let entryCount = dataSet.entryCount
                
                let shapeSize = dataSet.scatterShapeSize
                let lineHeight = valueFont.lineHeight
                
                for j in 0 ..< Int(ceil(CGFloat(entryCount) * phaseX))
                {
                    guard let e = dataSet.entryForIndex(i: j) else { break }
                    
                    pt.x = CGFloat(e.xIndex)
                    pt.y = CGFloat(e.value) * phaseY
                    pt = pt.applying(valueToPixelMatrix)
                    
                    if (!viewPortHandler.isInBoundsRight(x: pt.x))
                    {
                        break
                    }
                    
                    // make sure the lines don't do shitty things outside bounds
                    if ((!viewPortHandler.isInBoundsLeft(x: pt.x)
                        || !viewPortHandler.isInBoundsY(y: pt.y)))
                    {
                        continue
                    }
                    
                    let text = formatter.string(from: NSNumber(value: e.value))
                    
                    ChartUtils.drawText(
                        context: context,
                        text: text!,
                        point: CGPoint(
                            x: pt.x,
                            y: pt.y - shapeSize - lineHeight),
                        align: .center,
                        attributes: [NSFontAttributeName: valueFont, NSForegroundColorAttributeName: dataSet.valueTextColorAt(index: j)]
                    )
                }
            }
        }
    }
    
    public override func drawExtras(context: CGContext)
    {
        
    }
    
    private var _highlightPointBuffer = CGPoint()
    
    public override func drawHighlighted(context: CGContext, indices: [ChartHighlight])
    {
        guard let
            dataProvider = dataProvider,
            let scatterData = dataProvider.scatterData,
            let animator = animator
            else { return }
        
        let chartXMax = dataProvider.chartXMax
        
        context.saveGState()
        
        for high in indices
        {
            let minDataSetIndex = high.dataSetIndex == -1 ? 0 : high.dataSetIndex
            let maxDataSetIndex = high.dataSetIndex == -1 ? scatterData.dataSetCount : (high.dataSetIndex + 1)
            if maxDataSetIndex - minDataSetIndex < 1 { continue }
            
            for dataSetIndex in minDataSetIndex..<maxDataSetIndex
            {
                guard let set = scatterData.getDataSetByIndex(index: dataSetIndex) as? IScatterChartDataSet else { continue }
                
                if !set.isHighlightEnabled
                {
                    continue
                }
                
                context.setStrokeColor(set.highlightColor.cgColor)
                context.setLineWidth(set.highlightLineWidth)
                if (set.highlightLineDashLengths != nil)
                {
                    context.setLineDash(phase: set.highlightLineDashPhase, lengths: set.highlightLineDashLengths!)

                }
                else
                {
                    context.setLineDash(phase: CGFloat(0), lengths: [])
                }
                
                let xIndex = high.xIndex; // get the x-position
                
                if (CGFloat(xIndex) > CGFloat(chartXMax) * animator.phaseX)
                {
                    continue
                }
                
                let yVal = set.yValForXIndex(x: xIndex)
                if (yVal.isNaN)
                {
                    continue
                }
                
                let y = CGFloat(yVal) * animator.phaseY; // get the y-position
                
                _highlightPointBuffer.x = CGFloat(xIndex)
                _highlightPointBuffer.y = y
                
                let trans = dataProvider.getTransformer(which: set.axisDependency)
                
                trans.pointValueToPixel(point: &_highlightPointBuffer)
                
                // draw the lines
                drawHighlightLines(context: context, point: _highlightPointBuffer, set: set)
            }
        }
        
        context.restoreGState()
    }
}