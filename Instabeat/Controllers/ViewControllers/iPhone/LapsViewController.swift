//
//  TestSwimLibViewController.swift
//  Instabeat
//
//  Created by Dmytro on 5/13/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit
import RealmSwift

let poolLength: Double = 25

class LapsViewController: UIViewController, ChartViewDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var filterLabel: UILabel!
    @IBOutlet weak var filterPercentLabel: UILabel!
    
//    @IBOutlet weak var poolLenghtLabel: UILabel!
    @IBOutlet weak var scrollBarIndicatorViewPosition: NSLayoutConstraint!
    @IBOutlet weak var scrollBarIndicatorViewWidth: NSLayoutConstraint!
    @IBOutlet weak var scrollBarIndicatorView: UIView!
    
//    @IBOutlet weak var distanveView: UIView!
    var chartViewSetted: Bool = false
    var currentChartView: ChartViewBase!
    var session: Session!
    var currentFilter: Filter!
    var filteredLaps = List<Lap>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if currentFilter == nil {
            currentFilter = .all
        }
        let dateFormatter = DateFormatter.init()
        dateFormatter.dateFormat = "MMMM d"
        let usLocale = NSLocale.init(localeIdentifier: "en_US")
        dateFormatter.locale = usLocale as Locale!
        
        self.title = dateFormatter.string(from: session.date as Date).uppercased()
        
//        poolLenghtLabel.text = "\(Int(poolLength))m"
//        poolLenghtLabel.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !chartViewSetted {
            self.aplyFilter(filter: currentFilter)
        }
    }
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation,
                             duration: TimeInterval) {
        for subview in scrollView.subviews {
            if subview is LineChartView {
                (subview as! LineChartView).delegate  = nil
            }
            subview.removeFromSuperview()
        }
        scrollView.setContentOffset(CGPoint(x: 0, y: 0),
                                    animated: true)
    }
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        aplyFilter(filter: currentFilter)
    }
    
    func setupLapsLandscapeChartView(lapsCount: Int) -> BarChartView {
        let chartView = BarChartView()
        currentChartView = chartView
        let distanceBetweenXValues: CGFloat = 30
        chartView.delegate = self
        chartView.noDataText = "No data for chart"
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .Bottom
        xAxis.spaceBetweenLabels = 0
//        xAxis.axisMaxValue = Double(session!.laps.count) + 1
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
//        xAxis.axisLineColor = UIColor.clearColor()
        xAxis.labelTextColor = Constants.secondaryColors.lightGrey4Color
        
        let yAxis = chartView.leftAxis
        yAxis.drawZeroLineEnabled = false
        yAxis.labelTextColor = Constants.secondaryColors.lightGrey4Color
        yAxis.valueFormatter = NumberFormatter()
        yAxis.valueFormatter!.minimumFractionDigits = 0
        yAxis.drawGridLinesEnabled = false
        yAxis.axisLineColor = UIColor.clear
        yAxis.shouldConvertToSeconds = true
        chartView.rightAxis.enabled = false
        chartView.descriptionText = ""
        
        chartView.animate(yAxisDuration: 1.0)
        chartView.legend.enabled = false
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        //        chartView.keepPositionOnRotation = true
        chartView.scaleXEnabled = false
        chartView.autoScaleMinMaxEnabled = true
        chartView.dragEnabled = false
        //        chartView.backgroundColor = UIColor.whiteColor()
        chartView.frame = CGRect(x: 10,
                                 y: 0,
                                 width: distanceBetweenXValues * CGFloat(lapsCount + 1),
                                 height: scrollView.frame.height)
        return chartView
    }
    
    func setupLapsPortraitChartView(lapsCount: Int) -> LineChartView {
//        scrollBarIndicatorViewWidth.constant = scrollView.contentSize
        let chartView = LineChartView()
        currentChartView = chartView
        let distanceBetweenXValues: CGFloat = 30
        chartView.delegate = self
        chartView.noDataText = "No data for chart"
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .Bottom
        xAxis.spaceBetweenLabels = 0
        xAxis.yOffset = 15
        xAxis.axisMinValue = 0.55
        xAxis.axisMaxValue = Double(session!.laps.count)
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        xAxis.axisLineColor = UIColor.clear
        xAxis.labelTextColor = Constants.secondaryColors.lightGrey4Color
        
        let leftAxis = chartView.leftAxis
        leftAxis.labelPosition = .OutsideChart
        leftAxis.spaceTop = 0
        leftAxis.spaceBottom = 10
        leftAxis.axisMaxValue = poolLength + 0.1
        leftAxis.axisMinValue = -0.1
        leftAxis.spaceBottom = 0
        leftAxis.drawZeroLineEnabled = false
        leftAxis.drawGridLinesEnabled = false
        leftAxis.axisLineColor = UIColor.clear
        leftAxis.labelTextColor = UIColor.clear
        leftAxis.valueFormatter = NumberFormatter()
        leftAxis.valueFormatter!.minimumFractionDigits = 0
        
        chartView.rightAxis.enabled = false
        //        leftAxis.enabled = false
        chartView.descriptionText = ""
        chartView.animate(xAxisDuration: 1.0)
        chartView.legend.enabled = false
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        //        chartView.keepPositionOnRotation = true
        chartView.autoScaleMinMaxEnabled = true
        chartView.dragEnabled = false
        //        chartView.backgroundColor = UIColor.whiteColor()
        chartView.frame = CGRect(x: 0,
                                 y: 0,
                                 width: distanceBetweenXValues * CGFloat(lapsCount + 1),
                                 height: scrollView.frame.height)
        return chartView
    }
    
    func setChart(dataPoints: [NSNumber],
                  values: [Double],
                  colors: [UIColor],
                  laps: List<Lap>) {
        if UIApplication.shared.statusBarOrientation == .portrait {
//            distanveView.isHidden = false
            setPortraitChart(dataPoints: dataPoints,
                             values: values,
                             colors: colors,
                             laps: laps)
        }
        else {
//            distanveView.isHidden = true
            setLandscapeChart()
        }
    }
    
    func getColorZonesForLap(lap: Lap) -> (values: [Double], colors: [UIColor]) {
        var values: [Double] = []
        var colors: [UIColor] = []
        if lap.BPMS.isEmpty {
            return ([lap.duration], [Constants.primaryColors.mediumGreyColor])
        }
        var currentHeartRateZone = Utility.colorForHeartRateZone(heartRate: Int(lap.BPMS.first!.value),
                                                                 highlightedZone: .none)
        colors.append(currentHeartRateZone.color)
        var value: Double = 0
        for heartRate in lap.BPMS {
            let actualHeartRateZone = Utility.colorForHeartRateZone(heartRate: Int(heartRate.value), highlightedZone: .none)
            if actualHeartRateZone.zone != currentHeartRateZone.zone {
                colors.append(actualHeartRateZone.color)
                values.append(value)
                currentHeartRateZone.zone = actualHeartRateZone.zone
            }
            let currentTime = lap.duration - (lap.endTime - Double(heartRate.time))
            value = currentTime
        }
        values.append(value)
        return (values, colors)
    }
    
    func setLandscapeChart() {
        var xVals = [String](repeating:"", count: session!.laps.count + 1)
        var barChartDataEntries: [BarChartDataEntry] = []
        for i in 0..<session!.laps.count {
            let lap = session!.laps[i]
            let data = getColorZonesForLap(lap: lap)
            let chartDataEntry = BarChartDataEntry(values: data.values,
                                                   xIndex: i + 1,
                                                   colors: data.colors)
//            chartDataEntries.append(startLapChartDataEntry)
            barChartDataEntries.append(chartDataEntry)
        }
        
        let barChartDataSet = BarChartDataSet(yVals: barChartDataEntries,
                                              label: "Laps")
        barChartDataSet.barSpace = 0.83
//            barChartDataSet.drawCircleHighlightIndicatorEnabled = true
        barChartDataSet.drawValuesEnabled = false
        barChartDataSet.drawCircleHighlightIndicatorEnabled = true
        barChartDataSet.highlightColor = Constants.primaryColors.zoneRedColor
        barChartDataSet.highlightLineWidth = 1.0
        
        for  i in 1...session!.laps.count {
            if i % 5 == 0 {
                xVals[i] = "\(i)"
            }
        }
        
        let barChartData = BarChartData(xVals: xVals,
                                        dataSet: barChartDataSet)
        //        barChartData.groupSpace = 30
        
        let chartView = setupLapsLandscapeChartView(lapsCount: session!.laps.count)
        
        chartView.data = barChartData
        for subview in scrollView.subviews {
            subview.removeFromSuperview()
        }
        scrollView.addSubview(chartView)
        scrollView.contentSize = chartView.frame.size
        
        let scale = scrollView.frame.width / scrollView.contentSize.width
        if scale > 1.0 {
            scrollBarIndicatorView.isHidden = true
        }
        else {
            scrollBarIndicatorView.isHidden = false
            scrollBarIndicatorViewWidth.constant = scrollBarIndicatorView.frame.width * scale + 2
        }
        
    }
    
    func setPortraitChart(dataPoints: [NSNumber],
                          values: [Double],
                          colors: [UIColor],
                          laps: List<Lap>) {
        var dataEntries: [ChartDataEntry] = []
        var xVals = [String](repeating:"", count: laps.count + 2)
        var labelPositions: [ChartDataEntry] = []
        
        for i in 0..<dataPoints.count {
            let lap = laps[dataPoints[i].intValue - 1]
            let lastLap = session.laps.last!
            let dataEntry: ChartDataEntry!
            if lap.lapID == 1 {
                dataEntry = ChartDataEntry(value: values[i],
                                           xIndex: dataPoints[i].intValue,
                                           data:"\(lap.lapID),firstLap" as AnyObject?)
            }
            else if lap.lapID == lastLap.lapID {
                dataEntry = ChartDataEntry(value: values[i],
                                           xIndex: dataPoints[i].intValue,
                                           data:"\(lap.lapID),lastLap" as AnyObject?)
            }
            else {
                dataEntry = ChartDataEntry(value: values[i],
                                           xIndex: dataPoints[i].intValue,
                                           data:"\(lap.lapID),justLap" as AnyObject?)
            }
            dataEntries.append(dataEntry)
            labelPositions.append(ChartDataEntry(value: poolLength/2,
                                                 xIndex: dataPoints[i].intValue,
                                                 data: Utility.secondsToTimeString(lap.duration) as AnyObject?))
        }
        for  i in 1...laps.count {
            if currentFilter != .all {
                xVals[i] = "\(laps[i - 1].lapID)"
            }
            else {
                if i % 5 == 0 {
                    xVals[i] = "\(i)"
                }
            }
        }
        
        let lineChartDataSet = LineChartDataSet(yVals: dataEntries,
                                                label: "Laps")
//        lineChartDataSet.mode = .HorizontalBezier
        lineChartDataSet.drawCirclesEnabled = false
        lineChartDataSet.drawValuesEnabled = false
        lineChartDataSet.colors = colors
        lineChartDataSet.lineWidth = 5
        lineChartDataSet.drawCircleHighlightIndicatorEnabled = true
        lineChartDataSet.highlightColor = UIColor.white
        lineChartDataSet.highlightLineWidth = 1.0
//        lineChartDataSet.drawInfoEnabled = true
        
        let infoLabelsDataSet = LineChartDataSet(yVals:labelPositions,
                                                 label: "")
        infoLabelsDataSet.colors = [UIColor.clear]
        infoLabelsDataSet.drawCirclesEnabled = false
        infoLabelsDataSet.drawInfoEnabled = true
        infoLabelsDataSet.drawValuesEnabled = false
        infoLabelsDataSet.highlightEnabled = false
        infoLabelsDataSet.valueFont = UIFont.systemFont(ofSize: 12)
        infoLabelsDataSet.valueTextColor = UIColor.gray
        
//        chartView.xAxis.axisMaxValue = Double(laps.count + 3)
        
        let lineChartData = LineChartData(xVals: xVals,
                                          dataSets: [
                                            lineChartDataSet,
                                            infoLabelsDataSet
            ])
        let chartView = setupLapsPortraitChartView(lapsCount: laps.count)
        chartView.data = lineChartData
        for subview in scrollView.subviews {
            subview.removeFromSuperview()
        }
        scrollView.addSubview(chartView)
        scrollView.contentSize = chartView.frame.size
        
        let scale = scrollView.frame.width / scrollView.contentSize.width
        if scale > 1.0 {
            scrollBarIndicatorView.isHidden = true
        }
        else {
            scrollBarIndicatorView.isHidden = false
            scrollBarIndicatorViewWidth.constant = scrollBarIndicatorView.frame.width * scale + 2
        }
    }
    
    func chartValueSelected(chartView: ChartViewBase,
                            entry: ChartDataEntry,
                            dataSetIndex: Int,
                            highlight: ChartHighlight) {
        let lap = filteredLaps[highlight.xIndex - 1]
        
        let stroke: String!
        if lap.style == "Crawl"{
            stroke = "Front Crawl"
        }
        else {
            stroke = lap.style
        }
        
        let parentController = self.parent
        if parentController! is DashboardViewController{
            (parentController as! DashboardViewController).showInfoView(lap: String(format: "%02i", lap.lapID),
                                                                        heartRate:  "\(lap.averageHR)",
                pace: Utility.secondsToTimeString(lap.pace),
                stroke: stroke)
        }
        else if parentController! is  FilteringWrapperViewController {
            (parentController as! FilteringWrapperViewController).showInfoView(lap: String(format: "%02i", lap.lapID),
                                                                               heartRate: "\(lap.averageHR)",
                pace: Utility.secondsToTimeString(lap.pace),
                stroke: stroke)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(deselectChartView),
                                               name: Notification.Name("deselectChartView"),
                                               object: nil)
    }
    
    @IBAction func deselectChartViewByTap(_ sender: AnyObject) {
        deselectChartView()
    }
    func deselectChartView() {
        currentChartView.highlightValues(highs: nil)
        chartValueNothingSelected(chartView: currentChartView)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("deselectChartView"),
                                                  object: nil)
    }
    
    func chartValueNothingSelected(chartView: ChartViewBase) {
        let parentController = self.parent
        if parentController!  is DashboardViewController {
            (parentController as! DashboardViewController).hideInfoView()
        }
        else if parentController! is  FilteringWrapperViewController {
            (parentController as! FilteringWrapperViewController).hideInfoView()
        }
    }
    
    func aplyFilter(filter: Filter) {
//        UIHelper.showHUDWithStatus("Loading..")
//        lapInfoView.hidden = true
        //TODO: nedd to fix copy->paste
        filterPercentLabel.text = ""
        filterPercentLabel.textColor = Constants.secondaryColors.lightGrey5Color
        scrollView.setContentOffset(CGPoint.zero, animated: false)
        currentFilter = filter
        switch filter {
        case .zoneFat:
            filterLabel.text = "Zone: Fat"
            filterPercentLabel.textColor = Constants.primaryColors.zoneBlueColor
            let data = getZoneLaps(zone: .fat)
            if data.laps.isEmpty {
                UIHelper.showAlertControllerWith(title: "Error",
                                                 message: "No filtered data available",
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
                break
            }
            filterPercentLabel.text = String(format:"%.0f%%",
                                             data.percent)
            setChart(dataPoints: data.dataPoints,
                     values: data.values,
                     colors: data.colors,
                     laps: data.laps)
        case .zoneFit:
            filterLabel.text = "Zone: Fit"
            let data = getZoneLaps(zone: .fit)
            filterPercentLabel.textColor = Constants.primaryColors.zoneYellowColor
            if data.laps.isEmpty {
                UIHelper.showAlertControllerWith(title: "Error",
                                                 message: "No filtered data available",
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
                break
            }
            filterPercentLabel.text = String(format:"%.0f%%", data.percent)
            setChart(dataPoints: data.dataPoints,
                     values: data.values,
                     colors: data.colors,
                     laps: data.laps)
        case .zoneMax:
            filterLabel.text = "Zone: Max"
            filterPercentLabel.textColor = Constants.primaryColors.zoneRedColor
            let data = getZoneLaps(zone: .max)
            if data.laps.isEmpty {
                UIHelper.showAlertControllerWith(title: "Error",
                                                 message: "No filtered data available",
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
                break
            }
            filterPercentLabel.text = String(format:"%.0f%%", data.percent)
            setChart(dataPoints: data.dataPoints,
                     values: data.values,
                     colors: data.colors,
                     laps: data.laps)
        case .strokeBackstroke:
            filterLabel.text = "Stroke: Backstroke"
            let data = getStrokeLaps(style: "Backstroke")
            if data.laps.isEmpty {
                UIHelper.showAlertControllerWith(title: "Error",
                                                 message: "No filtered data available",
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
                break
            }
            filterPercentLabel.text = String(format:"%.0f%%", data.percent)
            setChart(dataPoints: data.dataPoints,
                     values: data.values,
                     colors: data.colors,
                     laps: data.laps)
        case .strokeButterfly:
            filterLabel.text = "Stroke: Butterfly"
            let data = getStrokeLaps(style: "Butterfly")
            if data.laps.isEmpty {
                UIHelper.showAlertControllerWith(title: "Error",
                                                 message: "No filtered data available",
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
                break
            }
            filterPercentLabel.text = String(format:"%.0f%%", data.percent)
            setChart(dataPoints: data.dataPoints,
                     values: data.values,
                     colors: data.colors,
                     laps: data.laps)
        case .strokeFreestyle:
            filterLabel.text = "Stroke: Freestyle"
            let data = getStrokeLaps(style: "Crawl")
            if data.laps.isEmpty {
                UIHelper.showAlertControllerWith(title: "Error",
                                                 message: "No filtered data available",
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
                break
            }
            filterPercentLabel.text = String(format:"%.0f%%", data.percent)
            setChart(dataPoints: data.dataPoints,
                     values: data.values,
                     colors: data.colors,
                     laps: data.laps)
        case .strokeBreaststroke:
            filterLabel.text = "Stroke: Breaststroke"
            let data = getStrokeLaps(style: "Breaststroke")
            if data.laps.isEmpty {
                UIHelper.showAlertControllerWith(title: "Error",
                                                 message: "No filtered data available",
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
                break
            }
            filterPercentLabel.text = String(format:"%.0f%%", data.percent)
            setChart(dataPoints: data.dataPoints,
                     values: data.values,
                     colors: data.colors,
                     laps: data.laps)
        default:
            //All
            filterLabel.text = "All"
            let data = getLaps(laps: session.laps, highlightedZone: .none)
            filterPercentLabel.text = ""
            setChart(dataPoints: data.dataPoints,
                     values: data.values,
                     colors: data.colors,
                     laps: data.laps)
        }
        chartViewSetted = true
    }
    
    private func getStrokeLaps(style :String) ->
        (dataPoints: [NSNumber],
        values: [Double],
        colors: [UIColor],
        laps: List<Lap>,
        percent: Float) {
            var laps = session.laps
            
            for _ in laps {
                if let index = laps.index(where: { $0.style != style }) {
                    laps.remove(at: index)
                }
            }
            let data = self.getLaps(laps: laps, highlightedZone: .none)
            let percent = Float(laps.count * 100 / session.laps.count)
            return (data.dataPoints,
                    data.values,
                    data.colors,
                    data.laps,
                    percent)
    }
    
    private func getZoneLaps(zone: HeartRateZone) ->
        (dataPoints: [NSNumber],
        values: [Double],
        colors: [UIColor],
        laps: List<Lap>,
        percent: Float) {
            let laps = List<Lap>()
            let bpms = List<HeartRate>()
            var totalBPMS: Float = 0
            for lap in session.laps {
                for BPM in lap.BPMS {
                    let zoneForBPM = Utility.colorForHeartRateZone(heartRate: Int(BPM.value),
                                                                   highlightedZone: .none).zone
                    if zoneForBPM == zone {
                        if laps.index(where: { $0.lapID == lap.lapID }) == nil {
                            laps.append(lap)
                        }
                        bpms.append(BPM)
                    }
                }
                totalBPMS += Float(lap.BPMS.count)
            }
            let data = self.getLaps(laps: laps, highlightedZone: zone)
            let percent = Float(bpms.count * 100) / totalBPMS
            return (data.dataPoints,
                    data.values,
                    data.colors,
                    data.laps,
                    percent)
    }
    //TODO: for i.....
    private func getLaps(laps: List<Lap>,
                         highlightedZone: HeartRateZone) ->
        (dataPoints: [NSNumber],
        values: [Double],
        colors: [UIColor],
        laps: List<Lap>) {
            var dataPoints: [NSNumber] = []
            var values: [Double] = []
            var colors: [UIColor] = []
            var xIndex = 1
            for i in  0..<laps.count {
                let lap = laps[i]
                var tmpValues: [Double] = []
                if lap.BPMS.isEmpty {
                    dataPoints.append(NSNumber(value: xIndex))
                    dataPoints.append(NSNumber(value: xIndex))
                    values.append(0)
                    values.append(poolLength)
                    colors.append(Utility.colorForHeartRateZone(heartRate: 0,
                                                                highlightedZone: .none).color)
                    break
                }
                else {
                    var currentHeartRateZone: HeartRateZone = .none
                    var value: Double = 0
                    for i in 0..<lap.BPMS.count {
                        let heartRate = lap.BPMS[i]
                        let actualHeartRateZone = Utility.colorForHeartRateZone(heartRate: Int(heartRate.value),
                                                                                highlightedZone: highlightedZone)
                        if actualHeartRateZone.zone != currentHeartRateZone {
                            if highlightedZone == .none || actualHeartRateZone.zone == highlightedZone {
                                colors.append(actualHeartRateZone.color)
                            }
                            else {
                                colors.append(Constants.primaryColors.mediumGreyColor)
                            }
                            tmpValues.append(value)
                            dataPoints.append(NSNumber(value: xIndex))
                            currentHeartRateZone = actualHeartRateZone.zone
                        }
                        let currentTime = lap.duration - (lap.endTime - Double(heartRate.time))
                        let percetTime = (currentTime / lap.duration)
                        let position = percetTime * poolLength
                        value = position
                    }
                    dataPoints.append(NSNumber(value: xIndex))
                    tmpValues.append(poolLength)
                    
                    if i % 2 == 0 {
                        values += tmpValues
                    }
                    else {
                        values += tmpValues.reversed()
                    }
                    if i < laps.count - 1 {
                        let nextLap = laps[i + 1]
                        if Int(nextLap.lapID) - Int(lap.lapID) > 1 {
                            colors.append(UIColor.clear)
                        }
                        else {
                            colors.append(colors.last!)
                        }
                    }
                    else {
                        colors.append(colors.last!)
                    }
                }
                xIndex += 1
            }
            filteredLaps = laps
            return (dataPoints, values, colors, laps)
    }
    
    //MARK: ScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scale = scrollView.frame.width / scrollView.contentSize.width
        scrollBarIndicatorViewPosition.constant = scrollView.contentOffset.x * scale
    }
}
