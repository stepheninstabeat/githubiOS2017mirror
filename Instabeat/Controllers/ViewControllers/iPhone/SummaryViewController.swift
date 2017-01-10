//
//  SummaryViewController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 7/15/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit

class SummaryViewController: UIViewController, ChartViewDelegate {
    var shouldDrawChartAnnimated = true
    var totalDistance: Int!
    var session: Session!
    var chartViewSetted: Bool = false
    var wrapperController: DashboardViewController!
    
    
    @IBOutlet weak var summaryChartView: PortraitBarChartView!
    
    @IBOutlet weak var chartViewHeight: NSLayoutConstraint!
    override func viewDidLoad() {
        super.viewDidLoad()
        summaryChartView.shouldDisplayTitle = false
        totalDistance = 1
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupChartView()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        summaryChartView.setup()
    }
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size,
                                 with: coordinator)
        for child in self.childViewControllers {
            if child as? HeartRateLineChartsViewController != nil {
                child.removeFromParentViewController()
            }
        }
        //device orientation portrait show only summary
        if size.width < size.height {
            let previousView = view.viewWithTag(34975)
            previousView?.removeFromSuperview()
        }
        else {
            //device orientation landscape need show BPM
            let newView: UIView!
            
            let heartRateViewController = self.storyboard!.instantiateViewController(withIdentifier: "BPMViewController") as! HeartRateLineChartsViewController
            heartRateViewController.shouldDrawChartAnnimated = shouldDrawChartAnnimated
            shouldDrawChartAnnimated = false
            heartRateViewController.session = session
            heartRateViewController.wrapperController = self.wrapperController
            newView = heartRateViewController.view
            heartRateViewController.didMove(toParentViewController: self)
            self.addChildViewController(heartRateViewController)
            newView.tag = 34975
            view.addSubview(newView)
            
            let leftConstraint = NSLayoutConstraint(item: newView,
                                                    attribute: .leading,
                                                    relatedBy: .equal,
                                                    toItem: view,
                                                    attribute: .leading,
                                                    multiplier: 1,
                                                    constant: 0)
            view.addConstraint(leftConstraint)
            
            let rightConstraint = NSLayoutConstraint(item: newView,
                                                     attribute: .trailing,
                                                     relatedBy: .equal,
                                                     toItem: view,
                                                     attribute: .trailing,
                                                     multiplier: 1,
                                                     constant: 0)
            view.addConstraint(rightConstraint)
            
            let topConstraint = NSLayoutConstraint(item: newView,
                                                   attribute: .top,
                                                   relatedBy: .equal,
                                                   toItem: view,
                                                   attribute: .top,
                                                   multiplier: 1,
                                                   constant: 0)
            view.addConstraint(topConstraint)
            
            let bottomConstraint = NSLayoutConstraint(item: newView,
                                                      attribute: .bottom,
                                                      relatedBy: .equal,
                                                      toItem: view,
                                                      attribute: .bottom,
                                                      multiplier: 1,
                                                      constant: 0)
            view.addConstraint(bottomConstraint)
            newView.translatesAutoresizingMaskIntoConstraints = false
            
            heartRateViewController.updateViewConstraints()
        }

    }
    
    func setupChartView() {
        let chartView = summaryChartView.chartView!
        chartView.delegate = self
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .Bottom
        xAxis.spaceBetweenLabels = 0
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

        Utility.getDataForBarChartView(bpms: session.bpms,
                                       totalDistance: Double(totalDistance),
                                       duration: session.duration,
                                       completionHandler: { values, colors in
                                        chartView.data = self.getChartData(values: values,
                                                                           colors: colors)
                                        self.summaryChartView.startChartView.backgroundColor = colors.first!
                                        self.summaryChartView.endChartView.backgroundColor = colors.last!
                                        UIView.animate(withDuration: 1.0) {
                                            self.chartViewHeight.constant = self.view.frame.height - 35
                                            self.view.layoutIfNeeded()
                                        }
        })
    }
    
    func getChartData(values: [Double],
                      colors: [UIColor]) -> BarChartData {
        var barChartDataEntries: [BarChartDataEntry] = []
        let chartDataEntry = BarChartDataEntry(values: values,
                                               xIndex: 1,
                                               colors: colors)
        barChartDataEntries.append(chartDataEntry)
        
        let barChartDataSet = BarChartDataSet(yVals: barChartDataEntries,
                                              label: "Laps")
        barChartDataSet.highlightEnabled = false
        barChartDataSet.drawValuesEnabled = false
        return BarChartData(xVals: ["", "", ""],
                            dataSet: barChartDataSet)
    }
    
    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {
        switch segue.identifier! {
        case "openBpmsChartViewController":
            let destination: HeartRateLineChartsViewController = segue.destination as! HeartRateLineChartsViewController
            destination.wrapperController = wrapperController
            destination.session = session
        default:
            break
        }
    }
}
