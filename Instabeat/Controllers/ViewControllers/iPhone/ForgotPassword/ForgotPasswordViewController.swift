//
//  ForgotPasswordViewController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 10/21/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit

class ForgotPasswordViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!
    var email: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        emailTextField.text = email
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideKeyboard(self)
        
    }
    @IBAction func back(_ sender: UIButton) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendResetLink(self)
        return true
    }
    
    @IBAction func hideKeyboard(_ sender: AnyObject) {
        emailTextField.resignFirstResponder()
    }
    
    @IBAction func sendResetLink(_ sender: AnyObject) {
        guard Utility.isValid(email: emailTextField.text!) else {
            UIHelper.showAlertControllerWith(title: "Reset Password Failed",
                                             message: "Password cannot be validated. Please try again.",
                                             inViewController: self,
                                             actionButtonTitle: "OK",
                                             actionHandler: nil)
            return
        }
            
        hideKeyboard(self)
        //TODO: if success sent request for reset password
        // 
        UIHelper.showAlertControllerWith(title: nil,
                                         message: "Email sent! Please check your inbox.",
                                         inViewController: self,
                                         actionButtonTitle: "OK",
                                         actionHandler: nil)
    }
    
}
