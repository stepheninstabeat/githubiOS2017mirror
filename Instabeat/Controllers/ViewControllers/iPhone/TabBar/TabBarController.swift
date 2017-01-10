//
//  TabBarController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 11/4/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    var tabbarFrameForPortrait: CGRect?
    private let errorMessage = "In order to calculate sessions data, please fill in Heart Rate Zones in your Profile settings"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        tabbarFrameForPortrait = tabBar.frame
        guard DataStorage.shared.activeUser.restingHR > 0 else {
            selectedIndex = 2
            return
        }
        guard Utility.validateUserHRZones(user: DataStorage.shared.activeUser) else {
            UIHelper.showAlertControllerWith(title: "HR Zones Eerror",
                                             message: "Some of Your HR zones can't be validated, please check it on settings page",
                                             inViewController: self,
                                             actionButtonTitle: "OK",
                                             actionHandler: nil)
            selectedIndex = 2
            return
        }
        selectedIndex = 1
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if UIApplication.shared.statusBarOrientation != .portrait {
            var tabFrame = tabBar.frame
            tabFrame.size.height = 0
            tabFrame.origin.y = tabBar.frame.size.height
            tabBar.frame = tabFrame
            tabBar.isHidden = true
        } else {
            if let oldFrame = tabbarFrameForPortrait {
                tabBar.frame = oldFrame
            }
            tabBar.isHidden = false
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {
        if UIApplication.shared.statusBarOrientation != .portrait {
            let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value,
                                      forKey: "orientation")
        }
        let index = viewControllers?.index(of: viewController)
        switch index! {
        case 0, 1:
            guard DataStorage.shared.activeUser.restingHR > 0 else {
                UIHelper.showAlertControllerWith(title: "Error",
                                                 message: errorMessage,
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
                return false
            }
        default:
            return true
        }
        return true
    }
}
