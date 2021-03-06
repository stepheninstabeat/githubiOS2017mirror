//
//  BubbleChartRenderer.swift
//  Charts
//
//  Bubble chart implementation:
//    Copyright 2015 Pierre-Marc Airoldi
//    Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation
import CoreGraphics

#if !os(OSX)
    import UIKit
#endif


public class BubbleChartRenderer: ChartDataRendererBase
{
    public weak var dataProvider: BubbleChartDataProvider?
    
    public init(dataProvider: BubbleChartDataProvider?, animator: ChartAnimator?, viewPortHandler: ChartViewPortHandler)
    {
        super.init(animator: animator, viewPortHandler: viewPortHandler)
        
        self.dataProvider = dataProvider
    }
    
    public override func drawData(context: CGContext)
    {
        guard let dataProvider = dataProvider, let bubbleData = dataProvider.bubbleData else { return }
        
        for set in bubbleData.dataSets as! [IBubbleChartDataSet]
        {
            if set.isVisible && set.entryCount > 0
            {
                drawDataSet(context: context, dataSet: set)
            }
        }
    }
    
    private func getShapeSize(
        entrySize: CGFloat,
                  maxSize: CGFloat,
                  reference: CGFloat,
                  normalizeSize: Bool) -> CGFloat
    {
        let factor: CGFloat = normalizeSize
            ? ((maxSize == 0.0) ? 1.0 : sqrt(entrySize / maxSize))
            : entrySize
        let shapeSize: CGFloat = reference * factor
        return shapeSize
    }
    
    private var _pointBuffer = CGPoint()
    private var _sizeBuffer = [CGPoint](repeating: CGPoint(), count: 2)
    
    public func drawDataSet(context: CGContext, dataSet: IBubbleChartDataSet)
    {
        guard let
            dataProvider = dataProvider,
            let animator = animator
            else { return }
        
        let trans = dataProvider.getTransformer(which: dataSet.axisDependency)
        
        let phaseX = max(0.0, min(1.0, animator.phaseX))
        let phaseY = animator.phaseY
        
        let entryCount = dataSet.entryCount
        
        let valueToPixelMatrix = trans.valueToPixelMatrix
        
        guard let
            entryFrom = dataSet.entryForXIndex(x: self.minX),
            let entryTo = dataSet.entryForXIndex(x: self.maxX)
            else { return }
        
        let minx = max(dataSet.entryIndex(entry: entryFrom), 0)
        let maxx = min(dataSet.entryIndex(entry: entryTo) + 1, entryCount)
        
        _sizeBuffer[0].x = 0.0
        _sizeBuffer[0].y = 0.0
        _sizeBuffer[1].x = 1.0
        _sizeBuffer[1].y = 0.0
        
        trans.pointValuesToPixel(pts: &_sizeBuffer)
        
        context.saveGState()
        
        let normalizeSize = dataSet.isNormalizeSizeEnabled
        
        // calcualte the full width of 1 step on the x-axis
        let maxBubbleWidth: CGFloat = abs(_sizeBuffer[1].x - _sizeBuffer[0].x)
        let maxBubbleHeight: CGFloat = abs(viewPortHandler.contentBottom - viewPortHandler.contentTop)
        let referenceSize: CGFloat = min(maxBubbleHeight, maxBubbleWidth)
        
        for j in minx ..< maxx
        {
            guard let entry = dataSet.entryForIndex(i: j) as? BubbleChartDataEntry else { continue }
            
            _pointBuffer.x = CGFloat(entry.xIndex - minx) * phaseX + CGFloat(minx)
            _pointBuffer.y = CGFloat(entry.value) * phaseY
            _pointBuffer = _pointBuffer.applying(valueToPixelMatrix)
            
            let shapeSize = getShapeSize(entrySize: entry.size, maxSize: dataSet.maxSize, reference: referenceSize, normalizeSize: normalizeSize)
            let shapeHalf = shapeSize / 2.0
            
            if (!viewPortHandler.isInBoundsTop(y: _pointBuffer.y + shapeHalf)
                || !viewPortHandler.isInBoundsBottom(y: _pointBuffer.y - shapeHalf))
            {
                continue
            }
            
            if (!viewPortHandler.isInBoundsLeft(x: _pointBuffer.x + shapeHalf))
            {
                continue
            }
            
            if (!viewPortHandler.isInBoundsRight(x: _pointBuffer.x - shapeHalf))
            {
                break
            }
            
            let color = dataSet.colorAt(index: entry.xIndex)
            
            let rect = CGRect(
                x: _pointBuffer.x - shapeHalf,
                y: _pointBuffer.y - shapeHalf,
                width: shapeSize,
                height: shapeSize
            )

            context.setFillColor(color.cgColor)
            context.fillEllipse(in: rect)
        }
        
        context.restoreGState()
    }
    
    public override func drawValues(context: CGContext)
    {
        guard let dataProvider = dataProvider,
            let bubbleData = dataProvider.bubbleData,
            let animator = animator
            else { return }
        
        // if values are drawn
        if (bubbleData.yValCount < Int(ceil(CGFloat(dataProvider.maxVisibleValueCount) * viewPortHandler.scaleX)))
        {
            guard let dataSets = bubbleData.dataSets as? [IBubbleChartDataSet] else { return }
            
            let phaseX = max(0.0, min(1.0, animator.phaseX))
            let phaseY = animator.phaseY
            
            var pt = CGPoint()
            
            for dataSet in dataSets
            {
                if !dataSet.isDrawValuesEnabled || dataSet.entryCount == 0
                {
                    continue
                }
                
                let alpha = phaseX == 1 ? phaseY : phaseX
                
                guard let formatter = dataSet.valueFormatter else { continue }
                
                let trans = dataProvider.getTransformer(which: dataSet.axisDependency)
                let valueToPixelMatrix = trans.valueToPixelMatrix
                
                let entryCount = dataSet.entryCount
                
                guard let
                    entryFrom = dataSet.entryForXIndex(x: self.minX),
                    let entryTo = dataSet.entryForXIndex(x: self.maxX)
                    else { continue }
                
                let minx = max(dataSet.entryIndex(entry: entryFrom), 0)
                let maxx = min(dataSet.entryIndex(entry: entryTo) + 1, entryCount)
                
                for j in minx ..< maxx
                {
                    guard let e = dataSet.entryForIndex(i: j) as? BubbleChartDataEntry else { break }
                    
                    let valueTextColor = dataSet.valueTextColorAt(index: j).withAlphaComponent(alpha)
                    
                    pt.x = CGFloat(e.xIndex - minx) * phaseX + CGFloat(minx)
                    pt.y = CGFloat(e.value) * phaseY
                    pt = pt.applying(valueToPixelMatrix)
                    
                    if (!viewPortHandler.isInBoundsRight(x: pt.x))
                    {
                        break
                    }
                    
                    if ((!viewPortHandler.isInBoundsLeft(x: pt.x) || !viewPortHandler.isInBoundsY(y: pt.y)))
                    {
                        continue
                    }
                    
                    let text = formatter.string(from: NSNumber(value: Float(e.size)))
                    
                    // Larger font for larger bubbles?
                    let valueFont = dataSet.valueFont
                    let lineHeight = valueFont.lineHeight

                    ChartUtils.drawText(
                        context: context,
                        text: text!,
                        point: CGPoint(
                            x: pt.x,
                            y: pt.y - (0.5 * lineHeight)),
                        align: .center,
                        attributes: [NSFontAttributeName: valueFont, NSForegroundColorAttributeName: valueTextColor])
                }
            }
        }
    }
    
    public override func drawExtras(context: CGContext)
    {
        
    }
    
    public override func drawHighlighted(context: CGContext, indices: [ChartHighlight])
    {
        guard let
            dataProvider = dataProvider,
            let bubbleData = dataProvider.bubbleData,
            let animator = animator
            else { return }
        
        context.saveGState()
        
        let phaseX = max(0.0, min(1.0, animator.phaseX))
        let phaseY = animator.phaseY
        
        for high in indices
        {
            let minDataSetIndex = high.dataSetIndex == -1 ? 0 : high.dataSetIndex
            let maxDataSetIndex = high.dataSetIndex == -1 ? bubbleData.dataSetCount : (high.dataSetIndex + 1)
            if maxDataSetIndex - minDataSetIndex < 1 { continue }
            
            for dataSetIndex in minDataSetIndex..<maxDataSetIndex
            {
                guard let dataSet = bubbleData.getDataSetByIndex(index: dataSetIndex) as? IBubbleChartDataSet
                    , dataSet.isHighlightEnabled
                    else { continue }
                
                let entries = dataSet.entriesForXIndex(x: high.xIndex)
                
                for entry in entries
                {
                    guard let entry = entry as? BubbleChartDataEntry
                        else { continue }
                    if !high.value.isNaN && entry.value != high.value { continue }
                    
                    let entryFrom = dataSet.entryForXIndex(x: self.minX)
                    let entryTo = dataSet.entryForXIndex(x: self.maxX)
                    
                    let minx = max(dataSet.entryIndex(entry: entryFrom!), 0)
                    let maxx = min(dataSet.entryIndex(entry: entryTo!) + 1, dataSet.entryCount)
                    
                    let trans = dataProvider.getTransformer(which: dataSet.axisDependency)
                    
                    _sizeBuffer[0].x = 0.0
                    _sizeBuffer[0].y = 0.0
                    _sizeBuffer[1].x = 1.0
                    _sizeBuffer[1].y = 0.0
                    
                    trans.pointValuesToPixel(pts: &_sizeBuffer)
                    
                    let normalizeSize = dataSet.isNormalizeSizeEnabled
                    
                    // calcualte the full width of 1 step on the x-axis
                    let maxBubbleWidth: CGFloat = abs(_sizeBuffer[1].x - _sizeBuffer[0].x)
                    let maxBubbleHeight: CGFloat = abs(viewPortHandler.contentBottom - viewPortHandler.contentTop)
                    let referenceSize: CGFloat = min(maxBubbleHeight, maxBubbleWidth)
                    
                    _pointBuffer.x = CGFloat(entry.xIndex - minx) * phaseX + CGFloat(minx)
                    _pointBuffer.y = CGFloat(entry.value) * phaseY
                    trans.pointValueToPixel(point: &_pointBuffer)
                    
                    let shapeSize = getShapeSize(entrySize: entry.size, maxSize: dataSet.maxSize, reference: referenceSize, normalizeSize: normalizeSize)
                    let shapeHalf = shapeSize / 2.0
                    
                    if (!viewPortHandler.isInBoundsTop(y: _pointBuffer.y + shapeHalf)
                        || !viewPortHandler.isInBoundsBottom(y: _pointBuffer.y - shapeHalf))
                    {
                        continue
                    }
                    
                    if (!viewPortHandler.isInBoundsLeft(x: _pointBuffer.x + shapeHalf))
                    {
                        continue
                    }
                    
                    if (!viewPortHandler.isInBoundsRight(x: _pointBuffer.x - shapeHalf))
                    {
                        break
                    }
                    
                    if (high.xIndex < minx || high.xIndex >= maxx)
                    {
                        continue
                    }
                    
                    let originalColor = dataSet.colorAt(index: entry.xIndex)
                    
                    var h: CGFloat = 0.0
                    var s: CGFloat = 0.0
                    var b: CGFloat = 0.0
                    var a: CGFloat = 0.0
                    
                    originalColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
                    
                    let color = NSUIColor(hue: h, saturation: s, brightness: b * 0.5, alpha: a)
                    let rect = CGRect(
                        x: _pointBuffer.x - shapeHalf,
                        y: _pointBuffer.y - shapeHalf,
                        width: shapeSize,
                        height: shapeSize)
                    
                    context.setLineWidth(dataSet.highlightCircleWidth)
                    context.setStrokeColor(color.cgColor)
                    context.strokeEllipse(in: rect)
                }
            }
        }
        
        context.restoreGState()
    }
}
