//
//  EditUserUIPresentationController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 12/7/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit

class EditUserUIPresentationController : UIPresentationController {
    let overlayTransparentView = UIView()
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let frame = CGRect(x: 0,
                           y: containerView!.bounds.height - 300,
                           width: containerView!.bounds.width,
                           height: 300)
        return frame
    }
    override func presentationTransitionWillBegin() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: NSNotification.Name.UIKeyboardWillShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: NSNotification.Name.UIKeyboardWillHide,
                                               object: nil)
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
            NotificationCenter.default.removeObserver(self,
                                                      name: NSNotification.Name.UIKeyboardWillShow,
                                                      object: nil)
            NotificationCenter.default.removeObserver(self,
                                                      name: NSNotification.Name.UIKeyboardWillHide,
                                                      object: nil)
        }
    }
    
    func keyboardWillShow(sender: NSNotification) {
        if UIScreen.main.bounds.size.height <= 568 {
            self.containerView!.frame.origin.y = -170
        } else {
            self.containerView!.frame.origin.y = -190
        }
    }
    
    func keyboardWillHide(sender: NSNotification) {
        self.containerView!.frame.origin.y = 0
    }
}
