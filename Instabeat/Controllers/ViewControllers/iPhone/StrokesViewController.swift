//
//  StrokesViewController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 7/19/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit
import RealmSwift

class StrokesViewController: UIViewController, ChartViewDelegate {
    
//    @IBOutlet weak var totalDistanceLabel: UILabel!
    
    @IBOutlet weak var freeStyleChartView: PortraitBarChartView!
    @IBOutlet weak var backstrokeChartView: PortraitBarChartView!
    @IBOutlet weak var breaststrokeChartView: PortraitBarChartView!
    @IBOutlet weak var butterflyChartView: PortraitBarChartView!
    
    @IBOutlet weak var freeStyleHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var backstrokeHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var breastrokeHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var butterflyHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var landscapeFreeStyleChartView: LandscapeBarCharView!
    @IBOutlet weak var landscapeBackstrokeChartView: LandscapeBarCharView!
    @IBOutlet weak var landscapeBreaststrokeChartView: LandscapeBarCharView!
    @IBOutlet weak var landscapeButterflyChartView: LandscapeBarCharView!
    @IBOutlet weak var landscapeRestChartView: LandscapeBarCharView!
    
    @IBOutlet weak var freeStyleWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var backstrokeWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var breastrokeWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var butterflyWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var restWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var chartsWrapperView: UIView!
    
    var totalDistance: Int!
    var session: Session!
    var chartViewSetted: Bool = false
    var wrapperController: DashboardViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        freeStyleChartView.setup()
        backstrokeChartView.setup()
        breaststrokeChartView.setup()
        butterflyChartView.setup()
        
        landscapeFreeStyleChartView.setup()
        landscapeBackstrokeChartView.setup()
        landscapeBreaststrokeChartView.setup()
        landscapeButterflyChartView.setup()
        landscapeRestChartView.setup()
        
        totalDistance = session.laps.count * Int(poolLength)
//        totalDistanceLabel.text = "\(totalDistance!)m"
//        totalDistanceLabel.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupChartView()
    }
    func setupChartView() {
        setupChartView(zone: .strokeFreestyle)
        setupChartView(zone: .strokeBackstroke)
        setupChartView(zone: .strokeBreaststroke)
        setupChartView(zone: .strokeButterfly)
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        setupChartView()
    }
    
    func setupChartView(zone: Filter) {
        var parentView: UIView!
        var chartView: BarChartView!
        var roundedValueForPercent: CGFloat!
        var data: (heartRates: List<HeartRate>, percent: CGFloat)!
        
        func configureChartViewByPercent(view: PortraitBarChartView, percent: CGFloat, constraint: NSLayoutConstraint, text: String) {
            roundedValueForPercent = percent * 100.0
            view.titleLabel.text = text + String(format:"%.0f%%",roundedValueForPercent)
            parentView = view
            chartView = view.chartView
            var height: CGFloat = percent * chartsWrapperView.frame.height
            if height == 0 {
                height = 44
            }
            else {
                height = height + 40
            }
            UIView.animate(withDuration: 1.0) {
                constraint.constant = height
                self.view.layoutIfNeeded()
            }
        }
        
        func configureLandscapeChartViewByPercent(view: LandscapeBarCharView,
                                                  percent: CGFloat,
                                                  constraint: NSLayoutConstraint,
                                                  text: String) {
            roundedValueForPercent = percent * 100.0
            view.titleLabel.text = text + String(format:"%.0f%%",roundedValueForPercent)
            parentView = view
            chartView = view.chartView
            let multiplier = chartsWrapperView.frame.width - 80
            
            var width: CGFloat = percent * multiplier + 10
            if width == 0 {
                width = 44
            }
            else {
                width = width + 40
            }
            UIView.animate(withDuration: 1.0) {
                constraint.constant = width
                self.view.layoutIfNeeded()
            }
        }
        
        switch zone {
        case .strokeFreestyle:
            data = getStrokeLaps(style: "Crawl")
            if UIApplication.shared.statusBarOrientation.isPortrait {
                configureChartViewByPercent(view: freeStyleChartView,
                                            percent: data.percent,
                                            constraint: freeStyleHeightConstraint,
                                            text: "FR ")
            }
            else {
                configureLandscapeChartViewByPercent(view: landscapeFreeStyleChartView,
                                            percent: data.percent,
                                            constraint: freeStyleWidthConstraint,
                                            text: "FR ")
            }
        case .strokeBackstroke:
            data = getStrokeLaps(style: "Backstroke")
            if UIApplication.shared.statusBarOrientation.isPortrait {
                configureChartViewByPercent(view: backstrokeChartView,
                                            percent: data.percent,
                                            constraint: backstrokeHeightConstraint,
                                            text: "BK ")
            }
            else {
                configureLandscapeChartViewByPercent(view: landscapeBackstrokeChartView,
                                                     percent: data.percent,
                                                     constraint: backstrokeWidthConstraint,
                                                     text: "BK ")
            }
        case .strokeBreaststroke:
            data = getStrokeLaps(style: "Breaststroke")
            if UIApplication.shared.statusBarOrientation.isPortrait {
                configureChartViewByPercent(view: breaststrokeChartView,
                                            percent: data.percent,
                                            constraint: breastrokeHeightConstraint,
                                            text: "BR ")
            }
            else {
                configureLandscapeChartViewByPercent(view: landscapeBreaststrokeChartView,
                                                     percent: data.percent,
                                                     constraint: breastrokeWidthConstraint,
                                                     text: "BR ")
            }
        case .strokeButterfly:
            data = getStrokeLaps(style: "Butterfly")
            if UIApplication.shared.statusBarOrientation.isPortrait {
                configureChartViewByPercent(view: butterflyChartView,
                                            percent: data.percent,
                                            constraint: butterflyHeightConstraint,
                                            text: "BF ")
            }
            else {
                configureLandscapeChartViewByPercent(view: landscapeButterflyChartView,
                                                     percent: data.percent,
                                                     constraint: butterflyWidthConstraint,
                                                     text: "BF ")
            }
        case .rest:
            print("rest")
        default:
            return
        }
        chartView.delegate = self
        chartView.noDataText = " "
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .Bottom
        xAxis.spaceBetweenLabels = 0
        xAxis.yOffset = 0
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        xAxis.axisLineColor = UIColor.clear
        xAxis.labelTextColor = Constants.secondaryColors.lightGrey4Color
        
        let yAxis = chartView.leftAxis
        yAxis.labelPosition = .OutsideChart
        yAxis.drawZeroLineEnabled = false
        yAxis.drawGridLinesEnabled = false
        yAxis.axisMinValue = 0
        yAxis.axisMaxValue = Double(totalDistance)
        yAxis.axisLineColor = UIColor.clear
        yAxis.labelTextColor = Constants.secondaryColors.lightGrey4Color
        yAxis.valueFormatter = NumberFormatter()
        yAxis.valueFormatter!.minimumFractionDigits = 0
        
        chartView.leftAxis.enabled = false
        chartView.rightAxis.enabled = false
        chartView.xAxis.enabled = false
        chartView.rightAxis.enabled = false
        chartView.descriptionText = ""
        
        chartView.legend.enabled = false
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        chartView.scaleXEnabled = false
        chartView.autoScaleMinMaxEnabled = false
        chartView.dragEnabled = false
        
        Utility.getDataForBarChartView(bpms: data.heartRates,
                                       totalDistance: Double(totalDistance),
                                       duration: session.duration,
                                       completionHandler: { values, colors in
                                        chartView.data = self.getChartData(values: values, colors: colors)
                                        if parentView  as? PortraitBarChartView != nil{
                                            (parentView as! PortraitBarChartView).startChartView.backgroundColor = colors.first!
                                            (parentView as! PortraitBarChartView).endChartView.backgroundColor = colors.last!
                                        }
                                        else {
                                            (parentView as! LandscapeBarCharView).startChartView.backgroundColor = colors.first!
                                            (parentView as! LandscapeBarCharView).endChartView.backgroundColor = colors.last!
                                        }
        })
        
    }
    
    private func getStrokeLaps(style: String) -> (heartRates: List<HeartRate>, percent: CGFloat) {
        let tmp = List<HeartRate>()
        var totalCount: CGFloat = 0
        for lap in session.laps {
            if lap.style == style {
                lap.BPMS.forEach{ tmp.append( $0 ) }
            }
            totalCount += CGFloat(lap.BPMS.count)
        }
        if !tmp.isEmpty {
            let percent = CGFloat(tmp.count) / totalCount
            return (tmp, percent)
        }
        return (tmp, 0)
    }
    
    func getData(bpms: [HeartRate]) -> (values: [Double], colors: [UIColor]) {
        var values: [Double] = []
        var colors: [UIColor] = []
        var currentHeartRateZone: HeartRateZone = .none
        var value: Double = 0
        for i in 0..<bpms.count {
            let heartRate = bpms[i]
            let actualHeartRateZone = Utility.colorForHeartRateZone(heartRate: Int(heartRate.value),
                                                                    highlightedZone: .none)
            if actualHeartRateZone.zone != currentHeartRateZone {
                colors.append(actualHeartRateZone.color)
                values.append(value)
                currentHeartRateZone = actualHeartRateZone.zone
            }
            let currentTime = Double(heartRate.time)
            let percetTime = currentTime / session.duration
            let position = percetTime * Double(totalDistance)
            value = position
        }
        values.append(Double(totalDistance))
        colors.append(colors.last!)
        return (values, colors)
    }
    
    func getChartData(values: [Double], colors: [UIColor]) -> BarChartData {
        var barChartDataEntries: [BarChartDataEntry] = []
        let chartDataEntry = BarChartDataEntry(values: values, xIndex:1, colors: colors)
        barChartDataEntries.append(chartDataEntry)
        
        let barChartDataSet = BarChartDataSet(yVals: barChartDataEntries, label: "Laps")
        barChartDataSet.highlightEnabled = false
        barChartDataSet.drawValuesEnabled = false
        barChartDataSet.colors = colors
        return BarChartData(xVals: ["", "", ""], dataSet: barChartDataSet)
    }
    @IBAction func openDetails(_ sender: AnyObject) {
        let backItem = UIBarButtonItem()
        backItem.title = "Strokes"
        self.navigationController?.navigationItem.backBarButtonItem = backItem
        let filteringViewController = self.storyboard!.instantiateViewController(withIdentifier: "filteringWrapperViewController") as! FilteringWrapperViewController
        switch (sender as! UITapGestureRecognizer).view!.tag {
        case 0:
            filteringViewController.currentFilter = .strokeFreestyle
        case 1:
            filteringViewController.currentFilter = .strokeBackstroke
        case 2:
            filteringViewController.currentFilter = .strokeBreaststroke
        case 3:
            filteringViewController.currentFilter = .strokeButterfly
        default:
            return
        }
        filteringViewController.session = session
        filteringViewController.isZoneFiltering = false
        self.navigationController?.pushViewController(filteringViewController, animated: true)
    }

}
