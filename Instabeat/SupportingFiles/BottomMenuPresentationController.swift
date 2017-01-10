//
//  BottomMenuPresentationController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 8/10/16.
//  Copyright © 2016 GL. All rights reserved.
//
import UIKit

class BottomMenuPresentationController : UIPresentationController {
    let overlayTransparentView = UIView()
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let frame = CGRect(x: 0,
                           y: containerView!.bounds.height * 0.25,
                           width: containerView!.bounds.width,
                           height: containerView!.bounds.height * 0.75)
        return frame
    }
    override func presentationTransitionWillBegin() {
        overlayTransparentView.frame = presentingViewController.view.frame
        overlayTransparentView.backgroundColor = UIColor (red: 0.2118,
                                                          green: 0.2118,
                                                          blue: 0.2314,
                                                          alpha: 1.0)
        self.overlayTransparentView.alpha = 0.0
        UIView.animate(withDuration: 0.3) {
            self.overlayTransparentView.alpha = 0.7
        }
        presentingViewController.view.addSubview(overlayTransparentView)
    }
    override func dismissalTransitionWillBegin() {
        UIView.animate(withDuration: 0.3) {
            self.overlayTransparentView.alpha = 0
        }
    }
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            overlayTransparentView.removeFromSuperview()
        }
    }
}
