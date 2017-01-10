//
//  ZonesViewController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 7/18/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit

class ZonesViewController: UIViewController, ChartViewDelegate {
    
    @IBOutlet weak var fatChartView: PortraitBarChartView!
    @IBOutlet weak var landscapeFatChartView: LandscapeBarCharView!
    @IBOutlet weak var fatHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var fatWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var fitChartView: PortraitBarChartView!
    @IBOutlet weak var landscapeFitChartView: LandscapeBarCharView!
    @IBOutlet weak var fitHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var fitWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var maxChartView: PortraitBarChartView!
    @IBOutlet weak var landscapeMaxChartView: LandscapeBarCharView!
    @IBOutlet weak var maxHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var maxWidthConstraint: NSLayoutConstraint!
    
//    @IBOutlet weak var totalDistanceLabel: UILabel!
    @IBOutlet weak var wrapperChartView: UIView!
    
    var totalDistance: Int!
    var session: Session!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fatChartView.setup()
        fitChartView.setup()
        maxChartView.setup()
        landscapeFatChartView.setup()
        landscapeFitChartView.setup()
        landscapeMaxChartView.setup()
        
        totalDistance = 1
//        totalDistanceLabel.text = "\(totalDistance!)m"
//        totalDistanceLabel.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupChartView()
    }
    func setupChartView() {
        setupChartView(zone: .zoneFat)
        setupChartView(zone: .zoneFit)
        setupChartView(zone: .zoneMax)
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        setupChartView()
    }
    
    func setupChartView(zone: Filter) {
        var parentView: UIView!
        var chartView: BarChartView!
        var color: UIColor
        var percent: Int
        var roundedValueForPercent: CGFloat!
        //TODO: remake this ugly code
        func configurePortraitChartViewByPercent(view: PortraitBarChartView,
                                                 percent: Int,
                                                 constraint: NSLayoutConstraint,
                                                 text: String) {
            let percent = CGFloat(percent)/100.0
            roundedValueForPercent = percent * 100.0
            view.titleLabel.text = text + String(format:"%.0f%%",roundedValueForPercent)
            parentView = view
            chartView = view.chartView
            let multiplier = wrapperChartView.frame.height
            var height: CGFloat = percent * multiplier + 10
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
                                                  percent: Int,
                                                  constraint: NSLayoutConstraint,
                                                  text: String) {
            let percent = CGFloat(percent)/100.0
            view.titleLabel.text = text + String(format:"%.0f%%",roundedValueForPercent)
            parentView = view
            chartView = view.chartView
            let multiplier = wrapperChartView.frame.width - 60
            
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
        case .zoneFat:
            percent = Utility.getPercentValue(zone: .fat,
                                              bpms: session.bpms)
            if UIApplication.shared.statusBarOrientation.isPortrait {
                configurePortraitChartViewByPercent(view: fatChartView,
                                                    percent: percent,
                                                    constraint: fatHeightConstraint,
                                                    text: "Fat ")
            }
            else {
                configureLandscapeChartViewByPercent(view: landscapeFatChartView,
                                                     percent: percent,
                                                     constraint: fatWidthConstraint,
                                                     text: "Fat ")
            }
            color = Constants.primaryColors.zoneBlueColor
        case .zoneFit:
            percent = Utility.getPercentValue(zone: .fit,
                                              bpms: session.bpms)
            if UIApplication.shared.statusBarOrientation.isPortrait {
                configurePortraitChartViewByPercent(view: fitChartView,
                                                    percent: percent,
                                                    constraint: fitHeightConstraint,
                                                    text: "Fit ")
            }
            else {
                configureLandscapeChartViewByPercent(view: landscapeFitChartView,
                                                     percent: percent,
                                                     constraint: fitWidthConstraint,
                                                     text: "Fit ")
            }
            color = Constants.primaryColors.zoneYellowColor
        case .zoneMax:
            percent = Utility.getPercentValue(zone: .max,
                                              bpms: session.bpms)
            if UIApplication.shared.statusBarOrientation.isPortrait {
                configurePortraitChartViewByPercent(view: maxChartView,
                                                    percent: percent,
                                                    constraint: maxHeightConstraint,
                                                    text: "Max ")
            }
            else {
                configureLandscapeChartViewByPercent(view: landscapeMaxChartView,
                                                     percent: percent,
                                                     constraint: maxWidthConstraint,
                                                     text: "Max ")
            }
            color = Constants.primaryColors.zoneRedColor
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
        yAxis.axisMaxValue = 100
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
        
        chartView.data = self.getChartData(values: [100], colors: [color])
        
        if parentView  as? PortraitBarChartView != nil{
            (parentView as! PortraitBarChartView).startChartView.backgroundColor = color
            (parentView as! PortraitBarChartView).endChartView.backgroundColor = color
        }
        else {
            (parentView as! LandscapeBarCharView).startChartView.backgroundColor = color
            (parentView as! LandscapeBarCharView).endChartView.backgroundColor = color
        }
    }
    
    func getChartData(values: [Double], colors: [UIColor]) -> BarChartData {
        var barChartDataEntries: [BarChartDataEntry] = []
        let chartDataEntry = BarChartDataEntry(values: values,
                                               xIndex:1,
                                               colors: colors)
        barChartDataEntries.append(chartDataEntry)
        
        let barChartDataSet = BarChartDataSet(yVals: barChartDataEntries,
                                              label: "")
        barChartDataSet.highlightEnabled = false
        barChartDataSet.drawValuesEnabled = false
        barChartDataSet.colors = colors
        return BarChartData(xVals: ["", "", ""],
                            dataSet: barChartDataSet)
    }
    
    @IBAction func openDetails(_ sender: UITapGestureRecognizer) {
//        let backItem = UIBarButtonItem()
//        backItem.title = "Zones"
//        navigationItem.backBarButtonItem = backItem
//        
//        let filteringViewController = self.storyboard!.instantiateViewController(withIdentifier: "filteringWrapperViewController") as! FilteringWrapperViewController
//        switch sender.view!.tag {
//        case 0:
//            filteringViewController.currentFilter = .zoneFat
//        case 1:
//            
//            filteringViewController.currentFilter = .zoneFit
//        case 2:
//            
//            filteringViewController.currentFilter = .zoneMax
//        default:
//            return
//        }
//        filteringViewController.session = session
//        filteringViewController.isZoneFiltering = true
//        self.navigationController?.pushViewController(filteringViewController, animated: true)
    }
}
