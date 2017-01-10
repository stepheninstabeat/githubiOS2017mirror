//
//  DashboardViewController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 7/12/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit

class DashboardViewController: UIViewController, UIViewControllerTransitioningDelegate {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet var titleLabels: [UILabel]!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var averageHRLabel: UILabel!
    @IBOutlet weak var maxHRLabel: UILabel!
    @IBOutlet weak var lapInfoView: UIView!
    @IBOutlet weak var lapInfoLabel: UILabel!
    @IBOutlet weak var lapHeartRateLabel: UILabel!
    @IBOutlet weak var lapStrokeLabel: UILabel!
    @IBOutlet weak var fatBurningZoneLabel: UILabel!
    @IBOutlet weak var fitZoneLabel: UILabel!
    @IBOutlet weak var maxBurningZoneLabel: UILabel!
    
    var session: Session!
    var tabBarVisible = true
    var isBottomMenuOpened = false
    
    override func viewDidLoad() {
        super.viewDidLoad()


    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem?.customView?.alpha = 1
        UIHelper.restrictRotation(restrict: false)
        configureInfoView()
    }
   
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.rightBarButtonItem?.customView?.alpha = 0
    }
    
    ///Configure info view for session
    private func configureInfoView () {
        Decorator.configure(segmentedControl: segmentedControl)
        if self.session == nil {
            guard DataStorage.shared.activeUser.sessions.count > 0 else {
                UIHelper.showAlertControllerWith(title: "Error",
                                                 message: "No sessions available",
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
                navigationItem.title = "No Sessions"
                return
            }
            self.session = DataStorage.shared.activeUser.sessions.last!
        }
        selectSection(segmentedControl)
        
        let tapGestureToHidePopup = UITapGestureRecognizer.init(target: self,
                                                                action: #selector(deselectChartView))
        lapInfoView.addGestureRecognizer(tapGestureToHidePopup)
        lapInfoView.isUserInteractionEnabled = true
        
        if let session = session {
            durationLabel.text = Utility.secondsToTimeString(session.duration)
            //        lapsLabel.text = "\(session.laps.count)"
            averageHRLabel.text = "\(session.averageHeartRate)"
            //        distanceLabel.text = " \(25 * session.laps.count)m "//25 pool lenght
            averageHRLabel.textColor = Utility.colorForHeartRateZone(heartRate: session.averageHeartRate,
                                                                     highlightedZone: .none).color
            if let maxHeartRate = session.maxHeartRate {
                maxHRLabel.text = String(format: "%i", Int(maxHeartRate.value))
                maxHRLabel.textColor = Utility.colorForHeartRateZone(heartRate: Int(maxHeartRate.value),
                                                                     highlightedZone: .none).color
            }
            fatBurningZoneLabel.text = "\(Utility.getPercentValue(zone: .fat, bpms: session.bpms))%"
            fitZoneLabel.text = "\(Utility.getPercentValue(zone: .fit, bpms: session.bpms))%"
            maxBurningZoneLabel.text = "\(Utility.getPercentValue(zone: .max, bpms: session.bpms))%"
            
            let dateFormatter = DateFormatter.init()
            dateFormatter.dateFormat = "MMM d"
            let usLocale = NSLocale.init(localeIdentifier: "en_US")
            dateFormatter.locale = usLocale as Locale!
            navigationItem.title = dateFormatter.string(from: session.date).uppercased()
        }
        
    }
    
    @IBAction func selectSection(_ sender: UISegmentedControl) {
        let viewController: UIViewController!
        let segmentedControl = sender
        UIHelper.restrictRotation(restrict: true)
        if session == nil {
            return
        }
        let storyboard = self.storyboard!
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            let summaryViewController = storyboard.instantiateViewController(withIdentifier: "summaryViewController") as! SummaryViewController
            summaryViewController.session = session
            summaryViewController.wrapperController = self
            UIHelper.restrictRotation(restrict: false)
            
            viewController = summaryViewController
        case 1:
            let zonesViewController = storyboard.instantiateViewController(withIdentifier: "zonesViewController") as! ZonesViewController
            zonesViewController.session = session
            //            zonesViewController.wrapperController = self
            
            viewController = zonesViewController
            //        case 2:
            //            let lapsViewController = storyboard.instantiateViewController(withIdentifier: "lapsViewController") as! LapsViewController
            //            lapsViewController.session = session
            //
            //            //            UIHelper.restrictRotation(restrict: false)
            //            //            lapsViewController.wrapperController = self
            //            viewController = lapsViewController
            //        case 3:
            ////            UIHelper.restrictRotation(true)
            //            let strokesViewController = storyboard.instantiateViewController(withIdentifier: "strokesViewController") as! StrokesViewController
            //            strokesViewController.session = session
            //            strokesViewController.wrapperController = self
            //
        //            viewController = strokesViewController
        default:
            return
        }
        addViewControllerToViewInPortrait(viewController: viewController)
        
    }
    internal func addViewControllerToViewInPortrait(viewController: UIViewController) {
        let newView = viewController.view!
        let previousView = view.viewWithTag(57698)
        previousView?.removeFromSuperview()
        for child in self.childViewControllers {
            child.removeFromParentViewController()
        }
        viewController.didMove(toParentViewController: self)
        self.addChildViewController(viewController)
        newView.tag = 57698
        newView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newView)
        //setup constrains
        let leftConstraint = NSLayoutConstraint(item: newView,
                                                attribute: .left,
                                                relatedBy: .equal,
                                                toItem: self.view,
                                                attribute: .left,
                                                multiplier: 1,
                                                constant: 0)
        
        view.addConstraint(leftConstraint)
        
        let rightConstraint = NSLayoutConstraint(item: newView,
                                                 attribute: .right,
                                                 relatedBy: .equal,
                                                 toItem: view,
                                                 attribute: .right,
                                                 multiplier: 1,
                                                 constant: 0)
        view.addConstraint(rightConstraint)
        
        let topConstraint = NSLayoutConstraint(item: newView,
                                               attribute: .top,
                                               relatedBy: .equal,
                                               toItem: lapInfoView,
                                               attribute: .bottom,
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
        
        viewController.updateViewConstraints()
    }
    //MARK: Info view
    func showInfoView(lap: String,
                      heartRate: String,
                      pace: String,
                      stroke: String) {
        lapInfoView.isHidden = false
        lapInfoLabel.text =  lap
        lapHeartRateLabel.text = heartRate
        lapStrokeLabel.text = stroke
    }
    
    func deselectChartView() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "deselectChartView"),
                                        object: nil)
    }
    
    func hideInfoView() {
        lapInfoView.isHidden = true
    }
    
    //MARK: Rotation
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation,
                             duration: TimeInterval) {
        if isBottomMenuOpened {
            self.dismiss(animated: false, completion: nil)
        }
        hideInfoView()
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if isBottomMenuOpened {
            openBottomMenu(false as AnyObject)
        }
    }
    
    @IBAction func openBottomMenu(_ sender: AnyObject) {
        let viewController = self.storyboard!.instantiateViewController(withIdentifier: "expandablePopupNavigationController") as! UINavigationController
        let tableViewController = viewController.viewControllers.first! as! ExpandablePopupTableViewController
        tableViewController.handleViewController = self
        if segmentedControl.selectedSegmentIndex == 1 {
            tableViewController.lapsTabSelected = true
        }
        
        viewController.modalPresentationStyle = UIModalPresentationStyle.custom
        viewController.transitioningDelegate = self
        var animated = true
        if sender as? Bool != nil {
            animated = sender as! Bool
        }
        self.present(viewController,
                     animated: animated,
                     completion: {
                        self.isBottomMenuOpened = true
        })
    }
    
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        return BottomMenuPresentationController(presentedViewController: presented,
                                                presenting: presenting)
    }
    
    func openFilteringViewController(filter: Filter) {
        dismiss(animated: true, completion: {
            self.isBottomMenuOpened = false
        })
        let filteringWrapperViewController = self.storyboard!.instantiateViewController(withIdentifier: "filteringWrapperViewController") as! FilteringWrapperViewController
        filteringWrapperViewController.session = session
        filteringWrapperViewController.currentFilter = filter
        if filter == .zoneFit || filter == .zoneFat || filter == .zoneMax {
            filteringWrapperViewController.isZoneFiltering = true
        }
        else {
            filteringWrapperViewController.isZoneFiltering = false
        }
        self.navigationController?.pushViewController(filteringWrapperViewController,
                                                      animated: true)
    }
    
    func openLapsDetails() {
        dismiss(animated: true, completion: {
            self.isBottomMenuOpened = false
        })
        let sessionDataTableViewController = self.storyboard!.instantiateViewController(withIdentifier: "sessionDataTableViewController") as! SessionDataTableViewController
        sessionDataTableViewController.session = session
        let backItem = UIBarButtonItem()
        backItem.title = "Laps"
        navigationItem.backBarButtonItem = backItem
        self.navigationController?.pushViewController(sessionDataTableViewController,
                                                      animated: true)
    }
   
}
