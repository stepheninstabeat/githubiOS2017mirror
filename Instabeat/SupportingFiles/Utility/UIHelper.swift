//
//  UIHelper.swift
//  Instabeat
//
//  Created by Dmytro on 5/11/16.
//  Copyright © 2016 GL. All rights reserved.
//

import Foundation
import SVProgressHUD

class UIHelper: NSObject {
    ///Show UIAlertController with title, message, actionButtonTitle in ViewController and actionHandler
    class func showAlertControllerWith(title: String?,
                                       message: String,
                                       inViewController sender: UIViewController,
                                       actionButtonTitle: String,
                                       actionHandler: (() -> Void)?) {

        SVProgressHUD.dismiss()
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title,
                                                    message: message,
                                                    preferredStyle: .alert)
            let action = UIAlertAction(title: actionButtonTitle,
                                       style: .default) {
                                        (action) in
                                        actionHandler?()
            }
            alertController.addAction(action)
            sender.present(alertController, animated: true, completion: nil)
            print("show message with title \(title) and message \(message)")
        }
    }
    
    /// Show message with status
    class func showHUDLoading() {
        SVProgressHUD.show()
    }
    
    /// Dissmiss message
    class func dismissHUD() {
        if SVProgressHUD.isVisible() {
            SVProgressHUD.dismiss()
            print("dismiss HUD")
        }
    }
    
    ///Restrict rotation
    class func restrictRotation(restrict: Bool) {
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.restrictRotation = restrict
    }
    
}

extension UIButton {
    @IBInspectable var IBCornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var IBBorderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var IBBorderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}

extension UITextField {
    @IBInspectable var placeHolderColor: UIColor? {
        get {
            return self.placeHolderColor
        }
        set {
            self.attributedPlaceholder = NSAttributedString(string: self.placeholder != nil ? self.placeholder! : "", attributes:[NSForegroundColorAttributeName: newValue!])
        }
    }
}
