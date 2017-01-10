//
// LineChartRenderer.swift
// Charts
//
// Created by Daniel Cohen Gindi on 4/3/15.
//
// Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
// A port of MPAndroidChart for iOS
// Licensed under Apache License 2.0
//
// https://github.com/danielgindi/Charts
//

import Foundation
import CoreGraphics

#if !os(OSX)
    import UIKit
#endif

public class LineChartRenderer: LineRadarChartRenderer
{
    public weak var dataProvider: LineChartDataProvider?
    
    public init(dataProvider: LineChartDataProvider?, animator: ChartAnimator?, viewPortHandler: ChartViewPortHandler)
    {
        super.init(animator: animator, viewPortHandler: viewPortHandler)
        
        self.dataProvider = dataProvider
    }
    
    public override func drawData(context: CGContext)
    {
        guard let lineData = dataProvider?.lineData else { return }
        
        for i in 0 ..< lineData.dataSetCount
        {
            guard let set = lineData.getDataSetByIndex(index: i) else { continue }
            
            if set.isVisible
            {
                if !(set is ILineChartDataSet)
                {
                    fatalError("Datasets for LineChartRenderer must conform to ILineChartDataSet")
                }
                
                drawDataSet(context: context, dataSet: set as! ILineChartDataSet)
            }
        }
    }
    
    public func drawDataSet(context: CGContext, dataSet: ILineChartDataSet)
    {
        let entryCount = dataSet.entryCount
        
        if (entryCount < 1)
        {
            return
        }
        
        context.saveGState()
        
        context.setLineWidth(dataSet.lineWidth)
        if (dataSet.lineDashLengths != nil)
        {
            context.setLineDash(phase: dataSet.lineDashPhase, lengths: dataSet.lineDashLengths!)
        }
        else
        {
            context.setLineDash(phase: CGFloat(0), lengths: [])
        }
        
        // if drawing cubic lines is enabled
        switch dataSet.mode
        {
        case .Linear: fallthrough
        case .Stepped:
            drawLinear(context: context, dataSet: dataSet)
            
        case .CubicBezier:
            drawCubicBezier(context: context, dataSet: dataSet)
            
        case .HorizontalBezier:
            drawHorizontalBezier(context: context, dataSet: dataSet)
        }
        
        context.restoreGState()
    }
    
    public func drawCubicBezier(context: CGContext, dataSet: ILineChartDataSet)
    {
        guard let
            trans = dataProvider?.getTransformer(which: dataSet.axisDependency),
            let animator = animator
            else { return }
        
        let entryCount = dataSet.entryCount
        
        guard let
            entryFrom = dataSet.entryForXIndex(x: self.minX < 0 ? 0 : self.minX, rounding: .Down),
            let entryTo = dataSet.entryForXIndex(x: self.maxX, rounding: .Up)
            else { return }
        
        let diff = (entryFrom == entryTo) ? 1 : 0
        let minx = max(dataSet.entryIndex(entry: entryFrom) - diff - 1, 0)
        let maxx = min(max(minx + 2, dataSet.entryIndex(entry: entryTo) + 1), entryCount)
        
        let phaseX = max(0.0, min(1.0, animator.phaseX))
        let phaseY = animator.phaseY
        
        // get the color that is specified for this position from the DataSet
        let drawingColor = dataSet.colors.first!
        
        let intensity = dataSet.cubicIntensity
        
        // the path for the cubic-spline
        let cubicPath = CGMutablePath()
        
        let valueToPixelMatrix = trans.valueToPixelMatrix
        
        let size = Int(ceil(CGFloat(maxx - minx) * phaseX + CGFloat(minx)))
        
        if (size - minx >= 2)
        {
            var prevDx: CGFloat = 0.0
            var prevDy: CGFloat = 0.0
            var curDx: CGFloat = 0.0
            var curDy: CGFloat = 0.0
            
            var prevPrev: ChartDataEntry! = dataSet.entryForIndex(i: minx)
            var prev: ChartDataEntry! = prevPrev
            var cur: ChartDataEntry! = prev
            var next: ChartDataEntry! = dataSet.entryForIndex(i: minx + 1)
            
            if cur == nil || next == nil { return }
            
            // let the spline start
            cubicPath.move(to: CGPoint(x: CGFloat(cur.xIndex), y: CGFloat(cur.value) * phaseY), transform: valueToPixelMatrix)
            for j in stride(from: (minx + 1), to: min(size, entryCount), by: 1)
            {
                prevPrev = prev
                prev = cur
                cur = next
                next = entryCount > j + 1 ? dataSet.entryForIndex(i: j + 1) : cur
                
                if next == nil { break }
                
                prevDx = CGFloat(cur.xIndex - prevPrev.xIndex) * intensity
                prevDy = CGFloat(cur.value - prevPrev.value) * intensity
                curDx = CGFloat(next.xIndex - prev.xIndex) * intensity
                curDy = CGFloat(next.value - prev.value) * intensity
                
                cubicPath.addCurve(to: CGPoint(x: CGFloat(cur.xIndex), y: CGFloat(cur.value) * phaseY), control1: CGPoint(x: CGFloat(prev.xIndex) + prevDx, y: (CGFloat(prev.value) + prevDy) * phaseY), control2: CGPoint(x: CGFloat(cur.xIndex) - curDx, y: (CGFloat(cur.value) - curDy) * phaseY), transform: valueToPixelMatrix)
            }
        }
        
        context.saveGState()
        
        if (dataSet.isDrawFilledEnabled)
        {
            // Copy this path because we make changes to it
            let fillPath = cubicPath.mutableCopy()
            
            drawCubicFill(context: context, dataSet: dataSet, spline: fillPath!, matrix: valueToPixelMatrix, from: minx, to: size)
        }
        
        if (dataSet.isDrawGradientEnabled) {
            drawGradientLine(context: context, dataSet: dataSet, spline: cubicPath, matrix: valueToPixelMatrix)
        } else {
            context.beginPath()
            context.addPath(cubicPath)
            context.setStrokeColor(drawingColor.cgColor)
            context.strokePath()
        }
        
        context.restoreGState()
        
    }
    
    public func drawHorizontalBezier(context: CGContext, dataSet: ILineChartDataSet)
    {
        guard let
            trans = dataProvider?.getTransformer(which: dataSet.axisDependency),
            let animator = animator
            else { return }
        
        let entryCount = dataSet.entryCount
        
        guard let
            entryFrom = dataSet.entryForXIndex(x: self.minX < 0 ? 0 : self.minX, rounding: .Down),
            let entryTo = dataSet.entryForXIndex(x: self.maxX, rounding: .Up)
            else { return }
        
        let diff = (entryFrom == entryTo) ? 1 : 0
        let minx = max(dataSet.entryIndex(entry: entryFrom) - diff, 0)
        let maxx = min(max(minx + 2, dataSet.entryIndex(entry: entryTo) + 1), entryCount)
        
        let phaseX = max(0.0, min(1.0, animator.phaseX))
        let phaseY = animator.phaseY
        
        // get the color that is specified for this position from the DataSet
        let drawingColor = dataSet.colors.first!
        
        // the path for the cubic-spline
        let cubicPath = CGMutablePath()
        
        let valueToPixelMatrix = trans.valueToPixelMatrix
        
        let size = Int(ceil(CGFloat(maxx - minx) * phaseX + CGFloat(minx)))
        
        if (size - minx >= 2)
        {
            var prev: ChartDataEntry! = dataSet.entryForIndex(i: minx)
            var cur: ChartDataEntry! = prev
            
            if cur == nil { return }
            
            // let the spline start
            cubicPath.move(to: CGPoint(x:CGFloat(cur.xIndex), y: CGFloat(cur.value) * phaseY), transform: valueToPixelMatrix)
            
            for j in stride(from: (minx + 1), to: min(size, entryCount), by: 1)
            {
                prev = cur
                cur = dataSet.entryForIndex(i: j)
                
                let cpx = CGFloat(prev.xIndex) + CGFloat(cur.xIndex - prev.xIndex) / 2.0
                cubicPath.addCurve(to: CGPoint(x: CGFloat(cur.xIndex), y: CGFloat(cur.value) * phaseY),
                                   control1: CGPoint(x: cpx, y: CGFloat(prev.value) * phaseY),
                                   control2: CGPoint(x: cpx, y: CGFloat(cur.value) * phaseY),
                                   transform: valueToPixelMatrix)
            }
        }
        
        context.saveGState()
        
        if (dataSet.isDrawFilledEnabled)
        {
            // Copy this path because we make changes to it
            let fillPath = cubicPath.mutableCopy()
            
            drawCubicFill(context: context, dataSet: dataSet, spline: fillPath!, matrix: valueToPixelMatrix, from: minx, to: size)
        }
        
        if (dataSet.isDrawGradientEnabled) {
            drawGradientLine(context: context, dataSet: dataSet, spline: cubicPath, matrix: valueToPixelMatrix)
        }
        else {
            context.beginPath()
            context.addPath(cubicPath)
            context.setStrokeColor(drawingColor.cgColor)
            context.strokePath()
        }
        context.restoreGState()
    }
    
    public func drawCubicFill(context: CGContext, dataSet: ILineChartDataSet, spline: CGMutablePath, matrix: CGAffineTransform, from: Int, to: Int)
    {
        guard let dataProvider = dataProvider else { return }
        
        if to - from <= 1
        {
            return
        }
        
        let fillMin = dataSet.fillFormatter?.getFillLinePosition(dataSet: dataSet, dataProvider: dataProvider) ?? 0.0
        
        // Take the from/to xIndex from the entries themselves,
        // so missing entries won't screw up the filling.
        // What we need to draw is line from points of the xIndexes - not arbitrary entry indexes!
        let xTo = dataSet.entryForIndex(i: to - 1)?.xIndex ?? 0
        let xFrom = dataSet.entryForIndex(i: from)?.xIndex ?? 0
        
        var pt1 = CGPoint(x: CGFloat(xTo), y: fillMin)
        var pt2 = CGPoint(x: CGFloat(xFrom), y: fillMin)
        pt1 = pt1.applying(matrix)
        pt2 = pt2.applying(matrix)
        
        spline.addLine(to: CGPoint(x: pt1.x, y: pt1.y))
        spline.addLine(to: CGPoint(x: pt2.x, y: pt2.y))
        spline.closeSubpath()
        
        if dataSet.fill != nil
        {
            drawFilledPath(context: context, path: spline, fill: dataSet.fill!, fillAlpha: dataSet.fillAlpha)
        }
        else
        {
            drawFilledPath(context: context, path: spline, fillColor: dataSet.fillColor, fillAlpha: dataSet.fillAlpha)
        }
    }
    
    private var _lineSegments = [CGPoint](repeating: CGPoint(), count: 2)
    
    public func drawLinear(context: CGContext, dataSet: ILineChartDataSet)
    {
        guard let
            trans = dataProvider?.getTransformer(which: dataSet.axisDependency),
            let animator = animator
            else { return }
        
        let valueToPixelMatrix = trans.valueToPixelMatrix
        
        let entryCount = dataSet.entryCount
        let isDrawSteppedEnabled = dataSet.mode == .Stepped
        let pointsPerEntryPair = isDrawSteppedEnabled ? 4 : 2
        
        let phaseX = max(0.0, min(1.0, animator.phaseX))
        let phaseY = animator.phaseY
        
        guard let
            entryFrom = dataSet.entryForXIndex(x: self.minX < 0 ? 0 : self.minX, rounding: .Down),
            let entryTo = dataSet.entryForXIndex(x: self.maxX, rounding: .Up)
            else { return }
        
        var diff = (entryFrom == entryTo) ? 1 : 0
        if dataSet.mode == .CubicBezier {
            diff += 1
        }
        
        let minx = max(dataSet.entryIndex(entry: entryFrom) - diff, 0)
        let maxx = min(max(minx + 2, dataSet.entryIndex(entry: entryTo) + 1), entryCount)
        
        context.saveGState()
        context.setLineCap(dataSet.lineCapType)
        
        // more than 1 color
        if (dataSet.colors.count > 1)
        {
            //add start line
            let firstEntry: ChartDataEntry! = dataSet.entryForIndex(i: 0)
            let stringData = firstEntry.data as! String
            let arrayData = stringData.characters.split{$0 == ","}.map(String.init)
            let firstLapIdentifier = arrayData.last!
            if firstLapIdentifier == "firstLap" || firstLapIdentifier == "oneLap" {
                _lineSegments[0].x = CGFloat(firstEntry.xIndex)
                _lineSegments[0].y = CGFloat(firstEntry.value)
                for i in 0..<_lineSegments.count
                {
                    _lineSegments[i] = _lineSegments[i].applying(valueToPixelMatrix)
                }
                _lineSegments[0].y -= dataSet.lineWidth / 2
                _lineSegments[1] = _lineSegments[0]
                _lineSegments[1].y += dataSet.lineWidth
                context.setLineWidth(dataSet.lineWidth * 4)
                context.setStrokeColor(dataSet.colors.first!.cgColor)
                context.strokeLineSegments(between: _lineSegments)
            }
        
            context.setLineWidth(dataSet.lineWidth)
            
            if (_lineSegments.count != pointsPerEntryPair) {
                _lineSegments = [CGPoint](repeating: CGPoint(), count: pointsPerEntryPair)
            }
            var count: Int!
            if firstLapIdentifier == "oneLap" {
                count = dataSet.entryCount
            }
            else {
                count = Int(ceil(CGFloat(maxx - minx) * phaseX + CGFloat(minx)))
            }
            for j in sequence(first: minx, next: { $0 + 1 <= count ? $0 + 1 : nil }) {
                if (count > 1 && j == count - 1) {
                    // Last point, we have already drawn a line to this point
                    break
                }
                
                var e: ChartDataEntry! = dataSet.entryForIndex(i: j)
                
                if e == nil { continue }
                
                _lineSegments[0].x = CGFloat(e.xIndex)
                _lineSegments[0].y = CGFloat(e.value) * phaseY
                if (j + 1 < count)
                {
                    e = dataSet.entryForIndex(i: j + 1)
                    
                    if e == nil { break }
                    
                    if isDrawSteppedEnabled
                    {
                        _lineSegments[1] = CGPoint(x: CGFloat(e.xIndex), y: _lineSegments[0].y)
                        _lineSegments[2] = _lineSegments[1]
                        _lineSegments[3] = CGPoint(x: CGFloat(e.xIndex), y: CGFloat(e.value) * phaseY)
                    }
                    else
                    {
                        _lineSegments[1] = CGPoint(x: CGFloat(e.xIndex), y: CGFloat(e.value) * phaseY)
                    }
                }
                else
                {
                    _lineSegments[1] = _lineSegments[0]
                }
                
                for i in 0..<_lineSegments.count
                {
                    _lineSegments[i] = _lineSegments[i].applying(valueToPixelMatrix)
                }
                
                if !viewPortHandler.isInBoundsRight(x: _lineSegments[0].x)
                {
                    break
                }
                
                // make sure the lines don't do shitty things outside bounds
                if !(viewPortHandler.isInBoundsLeft(x: _lineSegments[1].x)
                    || !(viewPortHandler.isInBoundsTop(y: _lineSegments[0].y) && !viewPortHandler.isInBoundsBottom(y: _lineSegments[1].y))
                    || !(viewPortHandler.isInBoundsTop(y: _lineSegments[0].y) && !viewPortHandler.isInBoundsBottom(y: _lineSegments[1].y)))
                {
                    continue
                }
                
                if _lineSegments[0].y == _lineSegments[1].y {
                    _lineSegments[0].x -= dataSet.lineWidth/2
                    _lineSegments[1].x += dataSet.lineWidth/2
                }
                
                // get the color that is set for this line-segment
                context.setStrokeColor(dataSet.colorAt(index: j).cgColor)
                context.strokeLineSegments(between: _lineSegments)
//                print(_lineSegments)
                if j == dataSet.entryCount - 2 {
                    //add end line
                    let lasstEntry: ChartDataEntry! = dataSet.entryForIndex(i: dataSet.entryCount-1)
                    let string = lasstEntry.data as! String
                    let array = string.characters.split{$0 == ","}.map(String.init)
                    let lastLapIdentifier = array.last!
                    if lastLapIdentifier == "lastLap" || lastLapIdentifier == "oneLap"{
                        _lineSegments[0].x = CGFloat(lasstEntry.xIndex)
                        _lineSegments[0].y = CGFloat(lasstEntry.value) * phaseY
                        for i in 0..<_lineSegments.count
                        {
                            _lineSegments[i] = _lineSegments[i].applying(valueToPixelMatrix)
                        }
                        _lineSegments[0].y -= dataSet.lineWidth / 2
                        _lineSegments[1] = _lineSegments[0]
                        _lineSegments[1].y += dataSet.lineWidth
                        context.setLineWidth(dataSet.lineWidth * 4)
                        context.setStrokeColor(dataSet.colors.last!.cgColor)
                        context.strokeLineSegments(between: _lineSegments)
                        context.setLineWidth(dataSet.lineWidth)
                    }
                }
            }
        }
        else
        { // only one color per dataset
            
            var e1: ChartDataEntry!
            var e2: ChartDataEntry!
            
            if (_lineSegments.count != max((entryCount - 1) * pointsPerEntryPair, pointsPerEntryPair))
            {
                _lineSegments = [CGPoint](repeating: CGPoint(), count: max((entryCount - 1) * pointsPerEntryPair, pointsPerEntryPair))
            }
            
            e1 = dataSet.entryForIndex(i: minx)
            
            if e1 != nil
            {
                let count = Int(ceil(CGFloat(maxx - minx) * phaseX + CGFloat(minx)))
                
                var j = 0
                
                for x in stride(from: count > 1 ? minx + 1 : minx, to: count, by: 1)
                {
                    e1 = dataSet.entryForIndex(i: x == 0 ? 0 : (x - 1))
                    e2 = dataSet.entryForIndex(i: x)
                    
                    if e1 == nil || e2 == nil { continue }
                    
                    _lineSegments[j] = CGPoint(
                        x: CGFloat(e1.xIndex),
                        y: CGFloat(e1.value) * phaseY
                        ).applying(
                            valueToPixelMatrix)
                    j += 1
                    
                    if isDrawSteppedEnabled
                    {
                        _lineSegments[j] = CGPoint(
                            x: CGFloat(e2.xIndex),
                            y: CGFloat(e1.value) * phaseY
                            ).applying(
                                valueToPixelMatrix)
                        j += 1
                        
                        _lineSegments[j] = CGPoint(
                            x: CGFloat(e2.xIndex),
                            y: CGFloat(e1.value) * phaseY
                            ).applying(
                                valueToPixelMatrix)
                        j += 1
                    }
                    
                    _lineSegments[j] = CGPoint(
                        x: CGFloat(e2.xIndex),
                        y: CGFloat(e2.value) * phaseY
                        ).applying(
                            valueToPixelMatrix)
                    j += 1
                }
                
                if j > 0
                {
                    context.setStrokeColor(dataSet.colorAt(index: 0).cgColor)
                    context.strokeLineSegments(between: _lineSegments)
                }
            }
        }
        
        // if drawing filled is enabled
        if (dataSet.isDrawFilledEnabled && entryCount > 0) {
            drawLinearFill(context: context, dataSet: dataSet, minx: minx, maxx: maxx, trans: trans)
        }
        if (dataSet.isDrawGradientEnabled) {
            let path = generatePath(
                dataSet: dataSet,
                fillMin: dataSet.fillFormatter?.getFillLinePosition(dataSet: dataSet, dataProvider: dataProvider!) ?? 0.0,
                from: minx,
                to: maxx,
                matrix: trans.valueToPixelMatrix)
            
            drawGradientLine(context: context, dataSet: dataSet, spline: path, matrix: valueToPixelMatrix)
        }
        context.restoreGState()
    }
    
    public func drawLinearFill(context: CGContext, dataSet: ILineChartDataSet, minx: Int, maxx: Int, trans: ChartTransformer)
    {
        guard let dataProvider = dataProvider else { return }
        
        let filled = generateFilledPath(
            dataSet: dataSet,
            fillMin: dataSet.fillFormatter?.getFillLinePosition(dataSet: dataSet, dataProvider: dataProvider) ?? 0.0,
            from: minx,
            to: maxx,
            matrix: trans.valueToPixelMatrix)
        
        if dataSet.fill != nil
        {
            drawFilledPath(context: context, path: filled, fill: dataSet.fill!, fillAlpha: dataSet.fillAlpha)
        }
        else
        {
            drawFilledPath(context: context, path: filled, fillColor: dataSet.fillColor, fillAlpha: dataSet.fillAlpha)
        }
    }
    
    /// Generates the path that is used for filled drawing.
    private func generateFilledPath(dataSet: ILineChartDataSet, fillMin: CGFloat, from: Int, to: Int, matrix: CGAffineTransform) -> CGPath
    {
        let phaseX = max(0.0, min(1.0, animator?.phaseX ?? 1.0))
        let phaseY = animator?.phaseY ?? 1.0
        let isDrawSteppedEnabled = dataSet.mode == .Stepped
        let matrix = matrix
        
        var e: ChartDataEntry!
        
        let filled = CGMutablePath()
        
        e = dataSet.entryForIndex(i: from)
        if e != nil
        {
            filled.move(to: CGPoint(x: CGFloat(e.xIndex), y: fillMin), transform: matrix)
            filled.addLine(to: CGPoint(x: CGFloat(e.xIndex), y: CGFloat(e.value) * phaseY), transform: matrix)
        }
        
        // create a new path
        for x in stride(from: (from + 1), to: Int(ceil(CGFloat(to - from) * phaseX + CGFloat(from))), by: 1)
        {
            guard let e = dataSet.entryForIndex(i: x) else { continue }
            
            if isDrawSteppedEnabled
            {
                guard let ePrev = dataSet.entryForIndex(i: x-1) else { continue }
                filled.addLine(to: CGPoint(x: CGFloat(e.xIndex), y: CGFloat(ePrev.value) * phaseY), transform: matrix)
            }
            filled.addLine(to: CGPoint(x: CGFloat(e.xIndex), y: CGFloat(e.value) * phaseY), transform: matrix)
        }
        
        // close up
        e = dataSet.entryForIndex(i: max(min(Int(ceil(CGFloat(to - from) * phaseX + CGFloat(from))) - 1, dataSet.entryCount - 1), 0))
        if e != nil
        {
            filled.addLine(to: CGPoint(x: CGFloat(e.xIndex), y: fillMin), transform: matrix)
        }
        filled.closeSubpath()
        
        return filled
    }
    
    /// Generates the path that is used for gradient drawing.
    private func generatePath(dataSet: ILineChartDataSet, fillMin: CGFloat, from: Int, to: Int, matrix: CGAffineTransform) -> CGPath
    {
        let matrix = matrix
        let phaseX = animator!.phaseX
        let phaseY = animator!.phaseY
        
        var e: ChartDataEntry!
        
        let generatedPath = CGMutablePath()
        e = dataSet.entryForIndex(i: from)
        if e != nil {
            generatedPath.move(to: CGPoint(x: CGFloat(e.xIndex), y: CGFloat(e.value) * phaseY), transform: matrix)
        }
        // create a new path
        let count = Int(ceil(CGFloat(to - from) * phaseX + CGFloat(from)))
        for x in from..<count
        {
            guard let e = dataSet.entryForIndex(i: x) else { continue }
            generatedPath.addLine(to: CGPoint(x: CGFloat(e.xIndex), y: CGFloat(e.value) * phaseY), transform: matrix)
        }
        return generatedPath
    }
    
    public override func drawValues(context: CGContext)
    {
        guard let
            dataProvider = dataProvider,
            let lineData = dataProvider.lineData,
            let animator = animator
            else { return }
        
        if (CGFloat(lineData.yValCount) < CGFloat(dataProvider.maxVisibleValueCount) * viewPortHandler.scaleX)
        {
            var dataSets = lineData.dataSets
            
            let phaseX = max(0.0, min(1.0, animator.phaseX))
            let phaseY = animator.phaseY
            
            var pt = CGPoint()
            
            for i in 0 ..< dataSets.count
            {
                guard let dataSet = dataSets[i] as? ILineChartDataSet else { continue }
                
                if !dataSet.isDrawValuesEnabled || dataSet.entryCount == 0
                {
                    continue
                }
                
                let valueFont = dataSet.valueFont
                
                guard let formatter = dataSet.valueFormatter else { continue }
                
                let trans = dataProvider.getTransformer(which: dataSet.axisDependency)
                let valueToPixelMatrix = trans.valueToPixelMatrix
                
                // make sure the values do not interfear with the circles
                var valOffset = Int(dataSet.circleRadius * 1.75)
                
                if (!dataSet.isDrawCirclesEnabled)
                {
                    valOffset = valOffset / 2
                }
                
                let entryCount = dataSet.entryCount
                
                guard let
                    entryFrom = dataSet.entryForXIndex(x: self.minX < 0 ? 0 : self.minX, rounding: .Down),
                    let entryTo = dataSet.entryForXIndex(x: self.maxX, rounding: .Up)
                    else { continue }
                
                var diff = (entryFrom == entryTo) ? 1 : 0
                if dataSet.mode == .CubicBezier
                {
                    diff += 1
                }
                
                let minx = max(dataSet.entryIndex(entry: entryFrom) - diff, 0)
                let maxx = min(max(minx + 2, dataSet.entryIndex(entry: entryTo) + 1), entryCount)
                
                for j in stride(from: minx, to: Int(ceil(CGFloat(maxx - minx) * phaseX + CGFloat(minx))), by: 1)
                {
                    guard let e = dataSet.entryForIndex(i: j) else { break }
                    
                    pt.x = CGFloat(e.xIndex)
                    pt.y = CGFloat(e.value) * phaseY
                    pt = pt.applying(valueToPixelMatrix)
                    
                    if (!viewPortHandler.isInBoundsRight(x: pt.x))
                    {
                        break
                    }
                    
                    if (!viewPortHandler.isInBoundsLeft(x: pt.x) || !viewPortHandler.isInBoundsY(y: pt.y))
                    {
                        continue
                    }
                    
                    ChartUtils.drawText(context: context,
                                        text: formatter.string(from: NSNumber(value: e.value))!,
                                        point: CGPoint(
                                            x: pt.x,
                                            y: pt.y - CGFloat(valOffset) - valueFont.lineHeight),
                                        align: .center,
                                        attributes: [NSFontAttributeName: valueFont, NSForegroundColorAttributeName: dataSet.valueTextColorAt(index: j)])
                }
            }
        }
    }
    
    public override func drawExtras(context: CGContext)
    {
        drawCircles(context: context)
    }
    
    private func drawCircles(context: CGContext)
    {
        guard let
            dataProvider = dataProvider,
            let lineData = dataProvider.lineData,
            let animator = animator
            else { return }
        
        let phaseX = max(0.0, min(1.0, animator.phaseX))
        let phaseY = animator.phaseY
        
        let dataSets = lineData.dataSets
        
        var pt = CGPoint()
        var rect = CGRect()
        
        context.saveGState()
        
        for i in 0 ..< dataSets.count
        {
            guard let dataSet = lineData.getDataSetByIndex(index: i) as? ILineChartDataSet else { continue }
            
            if !dataSet.isVisible || !dataSet.isDrawCirclesEnabled || dataSet.entryCount == 0
            {
                continue
            }
            
            let trans = dataProvider.getTransformer(which: dataSet.axisDependency)
            let valueToPixelMatrix = trans.valueToPixelMatrix
            
            let entryCount = dataSet.entryCount
            
            let circleRadius = dataSet.circleRadius
            let circleDiameter = circleRadius * 2.0
            let circleHoleRadius = dataSet.circleHoleRadius
            let circleHoleDiameter = circleHoleRadius * 2.0
            
            let drawCircleHole = dataSet.isDrawCircleHoleEnabled &&
                circleHoleRadius < circleRadius &&
                circleHoleRadius > 0.0
            let drawTransparentCircleHole = drawCircleHole &&
                (dataSet.circleHoleColor == nil ||
                    dataSet.circleHoleColor == NSUIColor.clear)
            
            guard let entryFrom = dataSet.entryForXIndex(x: self.minX < 0 ? 0 : self.minX, rounding: .Down),
                let entryTo = dataSet.entryForXIndex(x: self.maxX, rounding: .Up)
                else { continue }
            
            var diff = (entryFrom == entryTo) ? 1 : 0
            if dataSet.mode == .CubicBezier
            {
                diff += 1
            }
            
            let minx = max(dataSet.entryIndex(entry: entryFrom) - diff, 0)
            let maxx = min(max(minx + 2, dataSet.entryIndex(entry: entryTo) + 1), entryCount)
            
            for j in stride(from: minx, to: Int(ceil(CGFloat(maxx - minx) * phaseX + CGFloat(minx))), by: 1)
            {
                guard let e = dataSet.entryForIndex(i: j) else { break }
                
                pt.x = CGFloat(e.xIndex)
                pt.y = CGFloat(e.value) * phaseY
                pt = pt.applying(valueToPixelMatrix)
                
                if (!viewPortHandler.isInBoundsRight(x: pt.x))
                {
                    break
                }
                
                // make sure the circles don't do shitty things outside bounds
                if (!viewPortHandler.isInBoundsLeft(x: pt.x) || !viewPortHandler.isInBoundsY(y: pt.y))
                {
                    continue
                }
                
                context.setFillColor(dataSet.getCircleColor(index: j)!.cgColor)
                
                rect.origin.x = pt.x - circleRadius
                rect.origin.y = pt.y - circleRadius
                rect.size.width = circleDiameter
                rect.size.height = circleDiameter
                
                if drawTransparentCircleHole
                {
                    // Begin path for circle with hole
                    context.beginPath()
                    context.addEllipse(in: rect)
                    
                    // Cut hole in path
                    context.addArc(center: CGPoint(x: pt.x, y: pt.y), radius: circleHoleRadius, startAngle: 0.0, endAngle: CGFloat(M_PI_2), clockwise: true)
                    
                    // Fill in-between
                    context.fillPath()
                }
                else
                {
                    context.fillEllipse(in: rect)
                    
                    if drawCircleHole
                    {
                        context.setFillColor(dataSet.circleHoleColor!.cgColor)
                        
                        // The hole rect
                        rect.origin.x = pt.x - circleHoleRadius
                        rect.origin.y = pt.y - circleHoleRadius
                        rect.size.width = circleHoleDiameter
                        rect.size.height = circleHoleDiameter
                        
                        context.fillEllipse(in: rect)
                    }
                }
            }
        }
        
        context.restoreGState()
    }
    //MARK: Draw Info
    public func drawInfo(context: CGContext) {
        guard let
            dataProvider = dataProvider,
            let lineData = dataProvider.lineData,
            let animator = animator
            else { return }
        
        
        var dataSets = lineData.dataSets
        
        if dataSets.count == 1 {
            return
        }
        let phaseX = max(0.0, min(1.0, animator.phaseX))
        let phaseY = animator.phaseY
        
        var pt = CGPoint()
        let dataSet = dataSets[1] as! ILineChartDataSet
        if !dataSet.isDrawInfoEnabled {
            return
        }
        let valueFont = dataSet.valueFont
        
        //        let formatter = dataSet.valueFormatter
        
        let trans = dataProvider.getTransformer(which: dataSet.axisDependency)
        let valueToPixelMatrix = trans.valueToPixelMatrix
        
        // make sure the values do not interfear with the circles
        var valOffset = Int(dataSet.circleRadius * 1.75)
        
        if (!dataSet.isDrawCirclesEnabled)
        {
            valOffset = valOffset / 2
        }
        
        let entryCount = dataSet.entryCount
        
        guard let entryFrom = dataSet.entryForXIndex(x: self.minX < 0 ? 0 : self.minX, rounding: .Down),
                    let entryTo = dataSet.entryForXIndex(x: self.maxX, rounding: .Up)
        else { return }
        
        var diff = (entryFrom == entryTo) ? 1 : 0
        if dataSet.mode == .CubicBezier
        {
            diff += 1
        }
        
        let minx = max(dataSet.entryIndex(entry: entryFrom) - diff, 0)
        let maxx = min(max(minx + 2, dataSet.entryIndex(entry: entryTo) + 1), entryCount)
        
        for j in stride(from: minx, to: Int(ceil(CGFloat(maxx - minx) * phaseX + CGFloat(minx))), by: 1)
        {
            guard let e = dataSet.entryForIndex(i: j) else { break }
            
            pt.x = CGFloat(e.xIndex)
            pt.y = CGFloat(e.value) * phaseY
            pt = pt.applying(valueToPixelMatrix)
            
            if (!viewPortHandler.isInBoundsRight(x: pt.x))
            {
                break
            }
            
            if (!viewPortHandler.isInBoundsLeft(x: pt.x) || !viewPortHandler.isInBoundsY(y: pt.y))
            {
                continue
            }
            
            let point = CGPoint(
                x: pt.x,
                y: pt.y - valueFont.lineHeight)
            
            //            ChartUtils.drawText(context: context,
            //                                text: e.data as! String,
            //                                point: point,
            //                                attributes:  [NSFontAttributeName: valueFont, NSForegroundColorAttributeName: dataSet.valueTextColorAt(j)],
            //                                anchor: CGPoint(x: 0.5, y: 0.5),
            //                                angleRadians: CGFloat(-M_PI_2))
            
            let angleRadians = CGFloat(-M_PI_2)
            let attributes = [NSFontAttributeName: valueFont, NSForegroundColorAttributeName: dataSet.valueTextColorAt(index: j)]
            let text = e.data as! String
            let anchor = CGPoint(x: 0.5, y: 0)
            var drawOffset = CGPoint()
            
            
            let size = text.size(attributes: attributes)
            

            
            NSUIGraphicsPushContext(context: context)
            
            // Move the text drawing rect in a way that it always rotates around its center
            drawOffset.x = -size.width * 0.5
            drawOffset.y = -size.height * 0.5
            
            var translate = point
            
            // Move the "outer" rect relative to the anchor, assuming its centered
            if anchor.x != 0.5 || anchor.y != 0.5
            {
                let rotatedSize = CGSize(
                    width: abs(size.width * cos(angleRadians)) + abs(size.height * sin(angleRadians)),
                    height: abs(size.width * sin(angleRadians)) + abs(size.height * cos(angleRadians))
                )
                
                translate.x -= rotatedSize.width * (anchor.x - 0.5)
                translate.y -= rotatedSize.height * (anchor.y - 0.5)
            }
            context.move(to: CGPoint(x: translate.x, y: translate.y - size.width/2))
            context.addLine(to: CGPoint(x: translate.x, y: translate.y + size.width/2))
            context.setLineWidth(size.height)
            context.setLineCap(.round)
            
            context.setStrokeColor(UIColor.white.cgColor)
            context.strokePath()
            
            context.saveGState()
            context.translateBy(x: translate.x, y: translate.y)
            context.rotate(by: angleRadians)
            
            (text as NSString).draw(at: drawOffset, withAttributes: attributes)
            context.restoreGState()
            
            NSUIGraphicsPopContext()
        }
    }
    
    private var _highlightPointBuffer = CGPoint()
    
    public override func drawHighlighted(context: CGContext, indices: [ChartHighlight])
    {
        guard let
            lineData = dataProvider?.lineData,
            let chartXMax = dataProvider?.chartXMax,
            let animator = animator
            else { return }
        
        context.saveGState()
        
        for high in indices
        {
            let minDataSetIndex = high.dataSetIndex == -1 ? 0 : high.dataSetIndex
            let maxDataSetIndex = high.dataSetIndex == -1 ? lineData.dataSetCount : (high.dataSetIndex + 1)
            if maxDataSetIndex - minDataSetIndex < 1 { continue }
            
            for dataSetIndex in minDataSetIndex..<maxDataSetIndex
            {
                guard let set = lineData.getDataSetByIndex(index: dataSetIndex) as? ILineChartDataSet else { continue }
                
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
                
                let yValue = set.yValForXIndex(x: xIndex)
                if (yValue.isNaN)
                {
                    continue
                }
                let y = CGFloat(yValue) * animator.phaseY; // get the y-position
                
                _highlightPointBuffer.x = CGFloat(xIndex)
                
                if set.drawCircleHighlightIndicatorEnabled {
                    _highlightPointBuffer.y = CGFloat(set.yMax * 0.75)
                }
                else {
                    _highlightPointBuffer.y = y
                }
                
                let trans = dataProvider?.getTransformer(which: set.axisDependency)
                
                trans?.pointValueToPixel(point: &_highlightPointBuffer)
                
                // draw the lines
                drawHighlightLines(context: context, point: _highlightPointBuffer, set: set)
            }
        }
        
        context.restoreGState()
    }
    internal func drawGradientLine(context: CGContext, dataSet: ILineChartDataSet, spline: CGPath, matrix: CGAffineTransform)
    {
        context.saveGState()
        //CGPathCreateCopyByStrokingPath(spline, nil, dataSet.lineWidth, .Butt, .Miter, 10)
        let gradientPath = spline.copy(strokingWithWidth: dataSet.lineWidth, lineCap: .butt, lineJoin: .miter, miterLimit: 10)
        context.addPath(gradientPath)
        //CGContextAddPath(context, gradientPath)
        //        CGContextDrawPath(context, .Fill)
        
        //        let boundingBox = CGPathGetBoundingBox(gradientPath);
        let gradientStart = CGPoint(x: 0, y: viewPortHandler.chartHeight)
        let gradientEnd = CGPoint(x: 0, y: 0);
        var gradientLocations : [CGFloat] = []
        var gradientColors : [CGFloat] = []
        var cRed : CGFloat = 0
        var cGreen : CGFloat = 0
        var cBlue : CGFloat = 0
        var cAlpha : CGFloat = 0
        
        //Set lower bound color
        gradientLocations.append(0)
        var cColor = dataSet.colorAt(index: 0)
        if cColor.getRed(&cRed, green: &cGreen, blue: &cBlue, alpha: &cAlpha) {
            gradientColors += [cRed, cGreen, cBlue, cAlpha]
        }
        
        //Set middle colors
        for i in 0 ..< dataSet.gradientPositions!.count {
            var positionLocation = CGPoint(x: 0, y: dataSet.gradientPositions![i])
            positionLocation = positionLocation.applying(matrix)
            let normPositionLocation = (positionLocation.y - gradientStart.y) / (gradientEnd.y - gradientStart.y)
            if (normPositionLocation < 0) {
                gradientLocations.append(0)
            } else if (normPositionLocation > 1) {
                gradientLocations.append(1)
            } else {
                gradientLocations.append(normPositionLocation)
            }
        }
        for i in 0 ..< dataSet.colors.count {
            cColor = dataSet.colorAt(index: i)
            if cColor.getRed(&cRed, green: &cGreen, blue: &cBlue, alpha: &cAlpha) {
                gradientColors += [cRed, cGreen, cBlue, cAlpha]
            }
        }
        
        //Set upper bound color
        gradientLocations.append(1)
        cColor = dataSet.colorAt(index: dataSet.colors.count - 1)
        if cColor.getRed(&cRed, green: &cGreen, blue: &cBlue, alpha: &cAlpha) {
            gradientColors += [cRed, cGreen, cBlue, cAlpha]
        }
        
        //Define gradient
        let baseSpace = CGColorSpaceCreateDeviceRGB()
        var gradient: CGGradient?
        if (dataSet.gradientPositions!.count > 1) {
            gradient = CGGradient(colorSpace: baseSpace, colorComponents: gradientColors, locations: gradientLocations, count: gradientColors.count / 4)
        } else {
            gradient = CGGradient(colorSpace: baseSpace, colorComponents: gradientColors, locations: nil, count: gradientColors.count / 4)
        }
        //baseSpace = nil
        
        //Draw gradient path
        context.beginPath()
        context.addPath(gradientPath)
        context.clip()
        context.drawLinearGradient(gradient!, start: gradientStart, end: gradientEnd, options: CGGradientDrawingOptions(rawValue: 0))
        gradient = nil
        context.restoreGState()
    }
}
