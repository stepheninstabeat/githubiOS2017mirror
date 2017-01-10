//
//  Decorator.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 7/13/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit
import SVProgressHUD

class Decorator: NSObject {
    ///Configure segmented control depends on design
    class func configure(segmentedControl: UISegmentedControl) {
        let normalFont = Constants.fonts.blenderBook
        let normalTextAttributes: [NSObject : AnyObject] = [
            NSForegroundColorAttributeName as NSObject: UIColor.white,
            NSFontAttributeName as NSObject: normalFont!
        ]
        
        let selectedTextAttributes: [NSObject : AnyObject] = [
            NSForegroundColorAttributeName as NSObject: Constants.primaryColors.mediumGreyColor,
            NSFontAttributeName as NSObject: normalFont!
        ]
        segmentedControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(normalTextAttributes, for: .highlighted)
        segmentedControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
    }
    
    ///Configure UI elements appearance
    class func configureAppearance() {
        
        //MARK: SVProgressHUD appearance
        SVProgressHUD.setDefaultMaskType(.gradient)
        SVProgressHUD.setMinimumDismissTimeInterval(2.0)
        
        //MARK: UINavigationBar appearance
        UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: Constants.fonts.blenderBoldNavigationBar!,
                                                            NSForegroundColorAttributeName: UIColor.white]
        UINavigationBar.appearance().barTintColor = Constants.primaryColors.mediumGreyColor
        UINavigationBar.appearance().tintColor = Constants.primaryColors.whiteColor
        UINavigationBar.appearance().barStyle = .black
        UINavigationBar.appearance().isTranslucent = false
        //MARK: UIBarButtonItem appearance
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: Constants.fonts.blenderBoldNavigationBar!],
                                                            for: .normal)
        
        //MARK: UITabBarItem appearance
        UITabBarItem.appearance().setTitleTextAttributes([NSFontAttributeName: Constants.fonts.blenderBoldTabBar!],
                                                         for: .normal)
        UITabBarItem.appearance().titlePositionAdjustment = UIOffsetMake(0, -3.5)
        
//        UIView.appearance().tintColor = UIColor.clear
        
    }
}
