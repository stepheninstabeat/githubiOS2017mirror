//
//  SignupViewController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 10/20/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit

class SignupViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    private var textFieldsArray: [UITextField]!
    private var activeTextField: UITextField?
    private let dateFormatter = DateFormatter()
    override func viewDidLoad() {
        super.viewDidLoad()
        textFieldsArray = [
            emailTextField,
            nameTextField,
            lastNameTextField,
            passwordTextField,
            confirmPasswordTextField
        ]
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(),
                                                                    for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.none
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: NSNotification.Name.UIKeyboardWillShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: NSNotification.Name.UIKeyboardWillHide,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideKeyboard(self)
        self.navigationController?.isNavigationBarHidden = false
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.UIKeyboardWillShow,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.UIKeyboardWillHide,
                                                  object: nil)
        
    }
    
    @IBAction func back(_ sender: UIButton) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func signUpUser(_ sender: AnyObject) {
        //TODO: change duplicates code with error messages by error status code
        
        if (emailTextField.text?.isEmpty)! {
            UIHelper.showAlertControllerWith(title: "Sign Up Failed",
                                             message: "Email field cannot be empty.",
                                             inViewController: self,
                                             actionButtonTitle: "OK",
                                             actionHandler: nil)
            return
        }
        else {
            if !Utility.isValid(email: emailTextField.text!) {
                UIHelper.showAlertControllerWith(title: "Sign Up Failed",
                                                 message: "Email cannot be validated.",
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
                return
            }
        }
        if (nameTextField.text?.isEmpty)! {
            UIHelper.showAlertControllerWith(title: "Sign Up Failed",
                                             message: "Name field cannot be empty.",
                                             inViewController: self,
                                             actionButtonTitle: "OK",
                                             actionHandler: nil)
            return
        }
        
        if (passwordTextField.text?.isEmpty)! {
            UIHelper.showAlertControllerWith(title: "Sign Up Failed",
                                             message: "Password field cannot be empty.",
                                             inViewController: self,
                                             actionButtonTitle: "OK",
                                             actionHandler: nil)
            return
        }
        if (confirmPasswordTextField.text?.isEmpty)! {
            UIHelper.showAlertControllerWith(title: "Sign Up Failed",
                                             message: "Confirm password field cannot be empty.",
                                             inViewController: self,
                                             actionButtonTitle: "OK",
                                             actionHandler: nil)
            return
        }
        if passwordTextField.text != confirmPasswordTextField.text {
            UIHelper.showAlertControllerWith(title: "Sign Up Failed",
                                             message: "Passwords do not match!",
                                             inViewController: self,
                                             actionButtonTitle: "OK",
                                             actionHandler: nil)
            return
        }
        
        self.hideKeyboard(self)
        UIHelper.showHUDLoading()
        NetworkManager.shared.registrationUser(email: emailTextField.text!,
                                               password: passwordTextField.text!,
                                               confirmPassword: confirmPasswordTextField.text!,
                                               firstName: nameTextField.text!,
                                               lastName: lastNameTextField.text!,
                                               successHandler: { (token, userID) in
                                                NetworkManager.shared.getUser(userToken: token,
                                                                              successHandler: { (user) in
                                                                                DataStorage.shared.activeUser = user
                                                                                UIHelper.dismissHUD()
                                                                                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                                                                let landingPageViewController: UIViewController!
                                                                                
                                                                                landingPageViewController = storyboard.instantiateViewController(withIdentifier: "NavLandingPageViewController")
                                                                                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                                                                
                                                                                appDelegate.window?.rootViewController = landingPageViewController
                                                },
                                                                              failureHandler:  { (error) in
                                                                                UIHelper.showAlertControllerWith(title: "Error",
                                                                                                                 message: error,
                                                                                                                 inViewController: self,
                                                                                                                 actionButtonTitle: "OK",
                                                                                                                 actionHandler: nil)
                                                })
                                                
        },
                                               failureHandler: { (error) in
                                                UIHelper.showAlertControllerWith(title: "Error",
                                                                                 message: error,
                                                                                 inViewController: self,
                                                                                 actionButtonTitle: "OK",
                                                                                 actionHandler: nil)
        })
        
    }
    
    @IBAction func hideKeyboard(_ sender: AnyObject) {
        activeTextField?.resignFirstResponder()
    }
    
    //MARK: UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeTextField = nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField != textFieldsArray.last!{
            let indexOfTextField = textFieldsArray.index(of: textField)
            textFieldsArray[indexOfTextField! + 1].becomeFirstResponder()
        }
        else {
            signUpUser(self)
        }
        return true
    }
    
    
    func keyboardWillShow(sender: NSNotification) {
        if UIScreen.main.bounds.size.height <= 568 {
            self.view.frame.origin.y = -170
        } else {
            self.view.frame.origin.y = -190
        }
    }
    
    func keyboardWillHide(sender: NSNotification) {
        self.view.frame.origin.y = 0
    }
    
}
