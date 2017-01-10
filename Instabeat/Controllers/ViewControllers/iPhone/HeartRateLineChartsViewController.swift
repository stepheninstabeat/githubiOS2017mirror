//
// HeartRateLineChartsViewController.swift
// Instabeat
//
// Created by Dmytro on 5/25/16.
// Copyright © 2016 GL. All rights reserved.
//

import UIKit

class HeartRateLineChartsViewController: UIViewController, ChartViewDelegate {
    
    @IBOutlet weak var lineChartView: LineChartView!
    
    var shouldDrawChartAnnimated = true
    var session: Session!
    var wrapperController: UIViewController!
    var dataPoints: [Double] = []
    var values: [Double] = []
    var currentFilter: Filter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getChartData()
        setupChartView()
    }
    
    private func getChartData() {
        if !session.bpms.isEmpty {
            var count: Double = 0
            var avarageBPM: Double = 0
            var firstBPM: HeartRate = session.bpms.first!
            
            for bpm in session.bpms {
                if bpm.time - firstBPM.time > 3 {
                    dataPoints.append(bpm.time)
                    values.append(avarageBPM/count)
                    firstBPM = bpm
                    count = 0
                    avarageBPM = 0
                }
                avarageBPM += bpm.value
                count += 1
            }
            
        }
        if !session.laps.isEmpty {
            for time in dataPoints {
                var itemPresentInLap = false
                for lap in session.laps {
                    if (lap.startTime..<lap.endTime).contains(time) {
                        itemPresentInLap = true
                        break
                    }
                }
                if !itemPresentInLap {
                    if let indexOfObjectNotInLaps = dataPoints.index(of: time) {
                        dataPoints.remove(at: indexOfObjectNotInLaps)
                        values.remove(at: indexOfObjectNotInLaps)
                    }
                }
            }
        }
    }
    
    private func setupChartView() {
        lineChartView.delegate = self
        lineChartView.noDataText = "No data for chart"
        lineChartView.keepPositionOnRotation = false
        
        let xAxis = lineChartView.xAxis
        xAxis.labelPosition = .Bottom
        xAxis.spaceBetweenLabels = 1
        xAxis.drawGridLinesEnabled = false
        xAxis.axisLineColor = UIColor.clear
        xAxis.labelTextColor = UIColor (red: 0.7804,
                                        green: 0.7804,
                                        blue: 0.7804,
                                        alpha: 1.0)
        xAxis.shouldConvertToSeconds = true
        //xAxis.yOffset = 0.0
        
        let yAxis = lineChartView.leftAxis
        yAxis.labelPosition = .OutsideChart
        yAxis.axisMinValue = min(70, values.min() ?? 10) - 10
        yAxis.axisMaxValue = (values.max() ?? 0) + 10
        yAxis.drawGridLinesEnabled = false
        yAxis.drawZeroLineEnabled = false
        yAxis.valueFormatter = NumberFormatter()
        yAxis.valueFormatter?.positiveSuffix = "bpm"
        yAxis.valueFormatter!.minimumFractionDigits = 0
        yAxis.labelTextColor = UIColor (red: 0.7804,
                                        green: 0.7804,
                                        blue: 0.7804,
                                        alpha: 1.0)
        yAxis.axisLineColor = UIColor.clear
        let fatLimitLine = ChartLimitLine(limit: Double(DataStorage.shared.activeUser.fatBurningMaximumZone),
                                          label: "")
        fatLimitLine.lineColor = Constants.secondaryColors.lightGrey4Color
        fatLimitLine.lineWidth = 0.5
        yAxis.addLimitLine(line: fatLimitLine)
        
        let fitLimitLine = ChartLimitLine(limit: Double(DataStorage.shared.activeUser.fitnessMaximumZone),
                                          label: "")
        fitLimitLine.lineColor = Constants.secondaryColors.lightGrey4Color
        fitLimitLine.lineWidth = 0.5
        yAxis.addLimitLine(line: fitLimitLine)
        
        lineChartView.rightAxis.enabled = false
        lineChartView.scaleYEnabled = false
        lineChartView.descriptionText = ""
        lineChartView.doubleTapToZoomEnabled = false
        setChart(dataPoints: dataPoints,
                 values: values)
        if shouldDrawChartAnnimated {
            lineChartView.animate(xAxisDuration: 2.0)
        }
        lineChartView.viewPortHandler.setMaximumScaleY(yScale: 2)
        lineChartView.viewPortHandler.setMaximumScaleX(xScale: 2)
        lineChartView.highlightPerDragEnabled = false
        lineChartView.legend.enabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIDevice.current.setValue(1, forKey: "orientation")
    }
    
    func setChart(dataPoints: [Double],
                  values: [Double]) {
        var dataEntries: [ChartDataEntry] = []
        var xVals: [String] = [] 
        for i in 0..<dataPoints.count {
            let value = values[i]
            if value > 1 {
                let dataEntry = ChartDataEntry(value: value,
                                               xIndex:i)
                dataEntries.append(dataEntry)
            }
            xVals.append(String(describing: dataPoints[i]))
        }
        
        let lineChartDataSet = LineChartDataSet(yVals: dataEntries,
                                                label: "BPM")
        lineChartDataSet.mode = .CubicBezier
        lineChartDataSet.highlightEnabled = true
        lineChartDataSet.lineWidth = 4
//        lineChartDataSet.drawCircleHoleEnabled = false
        lineChartDataSet.drawCirclesEnabled = false
        lineChartDataSet.drawGradientEnabled = true
        lineChartDataSet.drawValuesEnabled = false
        lineChartDataSet.colors = [
            UIColor(red: 0.298, green: 0.6667, blue: 0.9216, alpha: 1.0),
            UIColor(red: 0.949, green: 0.8157, blue: 0.2353, alpha: 1.0),
            UIColor(red: 0.8039, green: 0.1333, blue: 0.302, alpha: 1.0)
        ]
        lineChartDataSet.gradientPositions = [
            DataStorage.shared.activeUser.fatBurningMiddleZone,
            DataStorage.shared.activeUser.fitnessMiddleZone,
            DataStorage.shared.activeUser.maximumPerformanceMiddleZone
            ].map({ CGFloat($0) })
        lineChartDataSet.drawHorizontalHighlightIndicatorEnabled = false
        lineChartDataSet.drawInfoEnabled = false
        lineChartDataSet.highlightColor = .white
        lineChartDataSet.highlightLineWidth = 0.5
        lineChartDataSet.setHigligtSelectedValueEnabled = true
        
        var dataSets: [LineChartDataSet] = []
        dataSets.append(lineChartDataSet)
        
//        if currentFilter != nil {
//            let zoneRage: Double
//            switch currentFilter! {
//            case .zoneMax:
//                zoneRage = Constants.heartRateZone.max
//                print("afdgf")
////            case .ZoneFit:
////                print("afdgf")
//////                zoneRange = [Constants.HeartRateZone.Fit...Constants.HeartRateZone.Max]
////            case .ZoneFat:
////                print("afdgf")
//////                zoneRange = [Constants.HeartRateZone.Fit...Constants.HeartRateZone.Max]
////            case .StrokeFreestyle:
////                print("afdgf")
//////                zoneRange = [Constants.HeartRateZone.Fit...Constants.HeartRateZone.Max]
////            case .StrokeBackstroke:
////                print("afdgf")
//////                zoneRange = [Constants.HeartRateZone.Fit...Constants.HeartRateZone.Max]
////            case .StrokeBreaststroke:
////                print("afdgf")
//////                zoneRange = [Constants.HeartRateZone.Fit...Constants.HeartRateZone.Max]
////            case .StrokeButterfly:
////                print("afdgf")
////                zoneRange = [Constants.HeartRateZone.Fit...Constants.HeartRateZone.Max]
//            default:
//                return
//            }
//            var colors: [UIColor] = []
//
//            for heartRate in dataPoints {
//                if heartRate.doubleValue >= zoneRage {
//                    colors.append(UIColor.clear)
//                }
//                else {
//                    colors.append(UIColor ( red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5 ))
//                }
//
//            }
//
//            let lineFilterChartDataSet = LineChartDataSet(yVals: dataEntries, label: "BPM")
//            lineFilterChartDataSet.mode = .CubicBezier
//            lineChartDataSet.drawHorizontalHighlightIndicatorEnabled = false
//            lineChartDataSet.setHigligtSelectedValueEnabled = false
//            lineChartDataSet.drawValuesEnabled = false
//            lineChartDataSet.drawGradientEnabled = false
//            lineChartDataSet.lineWidth = 4
//            lineChartDataSet.colors = colors
//            //filtered chart data with new colors
//
//            dataSets.append(lineFilterChartDataSet)
//        }
        
        var lapsDataEntries: [ChartDataEntry] = []
        for lap in session.laps {
            if !lap.BPMS.isEmpty {
                var index: Int!
                var value: Double!
                for reverseBPM in lap.BPMS.reversed() {
                    index = dataPoints.index(of: reverseBPM.time)
                    if index != nil {
                        value = values[index]
                        break
                    }
                }
                let dataEntry = ChartDataEntry(value: value, xIndex:index!)
                lapsDataEntries.append(dataEntry)
            }
        }
        
//        Utility.delay(delay: shouldDrawChartAnnimated ? 2.0 : 0.0, closure: {
//            let lapsChartDataSet = LineChartDataSet(yVals: lapsDataEntries, label: "BPM")
//            lapsChartDataSet.circleRadius = 2
//            lapsChartDataSet.circleColors = [UIColor ( red: 0.7804, green: 0.7804, blue: 0.7804, alpha: 1.0 )]
//
//            lapsChartDataSet.colors = [UIColor.clear]
//            lapsChartDataSet.mode = .CubicBezier
//            lapsChartDataSet.highlightEnabled = false
//            lapsChartDataSet.lineWidth = 4
//            lapsChartDataSet.drawValuesEnabled = false
//            // lapsChartDataSet.drawGradientEnabled = true
//            lapsChartDataSet.drawHorizontalHighlightIndicatorEnabled = false
//            lapsChartDataSet.drawVerticalHighlightIndicatorEnabled = false
//            lapsChartDataSet.drawInfoEnabled = false
//            lapsChartDataSet.highlightColor = UIColor.white
//            lapsChartDataSet.highlightLineWidth = 0.5
//            lapsChartDataSet.setHigligtSelectedValueEnabled = true
//            self.lineChartView.data?.addDataSet(d: lapsChartDataSet)
//            self.lineChartView.setVisibleXRange(minXRange: 0, maxXRange: CGFloat(xVals.count))
//            self.lineChartView.moveViewToX(xIndex: 0)
//        })

//        dataSets.append(lapsChartDataSet)
        
        let lineChartData = LineChartData(xVals: xVals,
                                          dataSets: dataSets)
        lineChartView.data = lineChartData
        lineChartView.setVisibleXRange(minXRange: 0,
                                       maxXRange: CGFloat(xVals.count))
    }
    
    //TODO: add filtering for zones and strokes
    func chartValueSelected(chartView: ChartViewBase,
                            entry: ChartDataEntry,
                            dataSetIndex: Int,
                            highlight: ChartHighlight) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deselectChartView),
                                               name: Notification.Name("deselectChartView"),
                                               object: nil)
        let lap = getLapBySelectedBPMValueIndex(index: highlight.xIndex)
        if wrapperController as? DashboardViewController != nil {
            (wrapperController as! DashboardViewController).showInfoView(lap: String(format: "%02i", lap?.lapID ?? "0"),
                                                                         heartRate: "\(Int(highlight.value))",
                pace: Utility.secondsToTimeString(lap?.pace ?? 0),
                stroke: lap?.style ?? "")
        }
    }
    
    @IBAction func deselectChartViewByTap(_ sender: AnyObject) {
        deselectChartView()
    }
    
    func deselectChartView() {
        lineChartView.highlightValues(highs: nil)
        chartValueNothingSelected(chartView: lineChartView)
    }
    
    func chartValueNothingSelected(chartView: ChartViewBase) {
        if let wrapperController = wrapperController as? DashboardViewController {
            wrapperController.hideInfoView()
        }
        NotificationCenter.default.removeObserver(self,
                                                  name: Notification.Name("deselectChartView"),
                                                  object: nil)
    }
    
    func getLapBySelectedBPMValueIndex(index: Int) -> Lap? {
        let time = dataPoints[index]
        var lap: Lap?
        for lapItem in session.laps {
            if (lapItem.startTime..<lapItem.endTime).contains(time) {
                lap = lapItem
                break
            }
            else if time < lapItem.startTime {
                lap  = session.laps.first!
            }
            else {
                lap = session.laps.last!
            }
        }
        return lap
    }
}
