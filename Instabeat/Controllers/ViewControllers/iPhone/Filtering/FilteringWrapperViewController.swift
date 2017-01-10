//
//  FilteringWrapperViewController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 7/22/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit

class FilteringWrapperViewController: UIViewController {
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var lapsLabel: UILabel!
    @IBOutlet weak var averageHRLabel: UILabel!
    //@IBOutlet weak var averagePaceLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    //lap info view
    @IBOutlet weak var filterLabel: UILabel!
    @IBOutlet weak var lapInfoView: UIView!
    @IBOutlet weak var lapInfoLabel: UILabel!
    @IBOutlet weak var lapHeartRateLabel: UILabel!
   // @IBOutlet weak var lapPaceLabel: UILabel!
    @IBOutlet weak var lapStrokeLabel: UILabel!
    
    var session: Session!
    var isZoneFiltering = false
    var currentFilter: Filter!
    var lapsViewController: LapsViewController!
    var heartRateViewController: HeartRateLineChartsViewController!
    var filteringArray: [Filter]!

    override func viewDidLoad() {
        super.viewDidLoad()
        let dateFormatter = DateFormatter.init()
        dateFormatter.dateFormat = "MMM d"
        let usLocale = NSLocale.init(localeIdentifier: "en_US")
        dateFormatter.locale = usLocale as Locale!
        navigationItem.title = (dateFormatter.string(from: session.date).uppercased())
        if isZoneFiltering {
            filteringArray = [Filter.zoneFat,
                              Filter.zoneFit,
                              Filter.zoneMax]
        }
        else {
            filteringArray = [Filter.strokeButterfly,
                              Filter.strokeFreestyle,
                              Filter.strokeBackstroke,
                              Filter.strokeBreaststroke]
        }
        
        let tapGestureToHidePopup = UITapGestureRecognizer.init(target: self,
                                                                action: #selector(deselectChartView))
        lapInfoView.addGestureRecognizer(tapGestureToHidePopup)
        lapInfoView.isUserInteractionEnabled = true
        
        configureInfoView()
        updateFilterLabel(filter: currentFilter)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIHelper.restrictRotation(restrict: true)
    }
  /*
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
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
//            heartRateViewController.shouldDrawChartAnnimated = shouldDrawChartAnnimated
//            shouldDrawChartAnnimated = false
            heartRateViewController.session = session
            heartRateViewController.wrapperController = self
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
    */
    private func configureInfoView () {
        durationLabel.text = Utility.secondsToTimeString(session.duration)
        lapsLabel.text = "\(session.laps.count)"
        averageHRLabel.text = "\(session.averageHeartRate)"
        //averagePaceLabel.text = Utility.secondsToTimeString(aSeconds: Double(session.sessionInfo!.averagePace))
        distanceLabel.text = " \(25 * session.laps.count)m "//25 pool lenght
        averageHRLabel.textColor = Utility.colorForHeartRateZone(heartRate: Int(session.averageHeartRate),
                                                                 highlightedZone: .none).color
    }
    
    @IBAction func nextFilter(_ sender: AnyObject) {
        var nextFilterIndex = filteringArray.index(of: currentFilter)! + 1
        if nextFilterIndex == filteringArray.count {
            nextFilterIndex = 0
        }
        currentFilter = filteringArray[nextFilterIndex]
        lapsViewController.aplyFilter(filter: currentFilter)
        updateFilterLabel(filter: currentFilter)
    }
   
    @IBAction func previousFilter(_ sender: AnyObject) {
        var previousFilterIndex = filteringArray.index(of: currentFilter)! - 1
        if previousFilterIndex < 0 {
            previousFilterIndex = filteringArray.count - 1
        }
        currentFilter = filteringArray[previousFilterIndex]
        lapsViewController.aplyFilter(filter: currentFilter)
        updateFilterLabel(filter: currentFilter)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "filteringStoryboardSegue":
            lapsViewController = segue.destination as! LapsViewController
            lapsViewController.session = session
            lapsViewController.currentFilter = currentFilter
        case "filteringLandscapeView":
            heartRateViewController = segue.destination as! HeartRateLineChartsViewController
            heartRateViewController.session = session
            heartRateViewController.currentFilter = currentFilter
        default:
            return
        }
    }
    //MARK: Info view
    func showInfoView(lap: String,
                          heartRate: String,
                          pace: String,
                          stroke: String) {
        lapInfoView.isHidden = false
        lapInfoLabel.text =  lap
        lapHeartRateLabel.text = heartRate
        //lapPaceLabel.text  = pace
        lapStrokeLabel.text = stroke
    }
    
    func hideInfoView() {
        lapInfoView.isHidden = true
    }
    
    func deselectChartView() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "deselectChartView"), object: nil)
    }
    
    func updateFilterLabel(filter: Filter) {
        switch filter {
        case .zoneFit:
            filterLabel.text = "ZONE / FIT"
        case .zoneFat:
            filterLabel.text = "ZONE / FAT"
        case .zoneMax:
            filterLabel.text = "ZONE / MAX"
        case .strokeBreaststroke:
            filterLabel.text = "STROKE / BREASTSTROKE"
        case .strokeBackstroke:
            filterLabel.text = "STROKE / BACKSTROKE"
        case .strokeButterfly:
            filterLabel.text = "STROKE / BUTTERFLY"
        case .strokeFreestyle:
            filterLabel.text = "STROKE / FREESTYLE"
        default:
            break
        }
    }
}
