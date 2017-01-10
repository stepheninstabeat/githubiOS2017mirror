//
//  EditUserDetailsTableViewController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 11/30/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

enum EditUserDetailsType {
    case firstName
    case lastName
    case email
    case password
    case birthday
}

class EditUserDetailsTableViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var currentDetailItemLabel: UILabel!
    @IBOutlet weak var newDetailItemLabel: UILabel!
    @IBOutlet weak var currentDetailItemTextField: UITextField!
    @IBOutlet weak var newDetailItemTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmWithPasswordLabel: UILabel!
    
    private var activeTextField: UITextField?
    private var isSaved = true
    
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter
    }()
    
    var handleViewController: UIViewController!
    
    var typeOfEdit: EditUserDetailsType = .firstName
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        tableView.backgroundColor = Constants.primaryColors.darkGrayColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navigationController = self.navigationController {
            let navigationBar = navigationController.navigationBar
            navigationBar.barTintColor = Constants.primaryColors.darkGrayColor
            navigationBar.isTranslucent = false
            let navTopBorder: UIView = UIView(frame: CGRect(x: 0,
                                                            y: 0,
                                                            width: navigationBar.frame.width,
                                                            height: 0.5))
            navTopBorder.backgroundColor = Constants.secondaryColors.whiteColor
            
            let navBotBorder: UIView = UIView(frame: CGRect(x: 0,
                                                            y: navigationBar.frame.size.height,
                                                            width: navigationBar.frame.width,
                                                            height: 0.5))
            navBotBorder.backgroundColor = Constants.primaryColors.darkGrayColor
            
            navigationBar.addSubview(navTopBorder)
            navigationBar.addSubview(navBotBorder)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    func configureView() {
        switch typeOfEdit {
        case .firstName:
            titleLabel.text = "FIRST NAME"
            currentDetailItemLabel.text = "Current Name"
            newDetailItemLabel.text = "New Name"
            currentDetailItemTextField.text = DataStorage.shared.activeUser.firstName
        case .lastName:
            titleLabel.text = "LAST NAME"
            currentDetailItemLabel.text = "Current Last Name"
            newDetailItemLabel.text = "New Last Name"
            currentDetailItemTextField.text = DataStorage.shared.activeUser.lastName
        case .email:
            titleLabel.text = "EMAIL ADDRESS"
            currentDetailItemLabel.text = "Current Email"
            newDetailItemLabel.text = "New Email"
            newDetailItemTextField.keyboardType = .emailAddress
            currentDetailItemTextField.text = DataStorage.shared.activeUser.email
        case .password:
            titleLabel.text = "PASSWORD"
            currentDetailItemLabel.text = "Current Password"
            newDetailItemLabel.text = "New Password"
            currentDetailItemTextField.isSecureTextEntry = true
            newDetailItemTextField.isSecureTextEntry = true
            currentDetailItemTextField.isEnabled = true
            confirmWithPasswordLabel.text = "Confirm New Password"
        case .birthday:
            titleLabel.text = "DAY OF BIRTH"
            currentDetailItemLabel.text = "Current Day Of Birth"
            newDetailItemLabel.text = "New Day Of Birth"
            confirmWithPasswordLabel.text = "Confirm New Password"
            newDetailItemTextField.tag = 13
            if let birthday = DataStorage.shared.activeUser.birthday {
                currentDetailItemTextField.text = dateFormatter.string(from: birthday)
            } else {
                currentDetailItemTextField.text = "Unknown"
            }
        }
    }
    
    @IBAction func sentUpdateUserDetailsRequest(_ sender: UIButton) {
        var passwordTF: UITextField = passwordTextField
        
        var userParameterToUpdate = [UserParameter: Any]()
        switch typeOfEdit {
        case .firstName:
            userParameterToUpdate[.firstName] = newDetailItemTextField.text!
        case .lastName:
            userParameterToUpdate[.lastName] = newDetailItemTextField.text!
        case .email:
            guard DataStorage.shared.activeUser.email != newDetailItemTextField.text else {
                UIHelper.showAlertControllerWith(title: "Error",
                                                 message: "Looks like you entered the same email address",
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
                return
            }
            userParameterToUpdate[.email] = newDetailItemTextField.text!
        case .password:
            if newDetailItemTextField.text != passwordTextField.text {
                UIHelper.showAlertControllerWith(title: "Error",
                                                 message: "Passwords do not match",
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
                return
            }
            guard KeychainWrapper.standard.string(forKey: "InstabeatUserPassword") != newDetailItemTextField.text else {
                UIHelper.showAlertControllerWith(title: "Error",
                                                 message: "Your new password should be different than your current one.",
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
                return
            }
            passwordTF = currentDetailItemTextField
            userParameterToUpdate[.password] = newDetailItemTextField.text!
        case .birthday:
            userParameterToUpdate[.birthday] = newDetailItemTextField.text!
        }
        
        if typeOfEdit != .lastName && typeOfEdit != .firstName {
            guard KeychainWrapper.standard.string(forKey: "InstabeatUserPassword") == passwordTF.text else {
                UIHelper.showAlertControllerWith(title: "Error",
                                                 message: "Entered password is wrong. Please try again.",
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
                return
            }
        }
        activeTextField?.resignFirstResponder()
        UIHelper.showHUDLoading()
        NetworkManager.shared.updateUserInformation(userParameterToUpdate,
                                                    successHandler: { user in
                                                        UIHelper.dismissHUD()
                                                        DatabaseManager.shared.realm.beginWrite()
                                                        
                                                        switch self.typeOfEdit {
                                                        case .firstName:
                                                            DataStorage.shared.activeUser.firstName = self.newDetailItemTextField.text!
                                                        case .lastName:
                                                            DataStorage.shared.activeUser.lastName = self.newDetailItemTextField.text!
                                                        case .email:
                                                            DataStorage.shared.activeUser.email = self.newDetailItemTextField.text!
                                                            KeychainWrapper.standard.set(self.newDetailItemTextField.text!, forKey: "InstabeatUserEmail")
                                                        case .password:
                                                            KeychainWrapper.standard.set(self.newDetailItemTextField.text!, forKey: "InstabeatUserPassword")
                                                        case .birthday:
                                                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "BirthdayUpdated"), object: nil)
                                                            DataStorage.shared.activeUser.birthday = self.dateFormatter.date(from: self.newDetailItemTextField.text!)
                                                        }
                                                        do {
                                                            try DatabaseManager.shared.realm.commitWrite()
//                                                            DatabaseManager.shared.save(user: DataStorage.shared.activeUser,
//                                                                                        failure: nil)
                                                        }
                                                        catch { }
                                                        self.handleViewController.dismiss(animated: true,
                                                                                          completion: nil)
        },
                                                    failureHandler: { error in
                                                        UIHelper.dismissHUD()
                                                        UIHelper.showAlertControllerWith(title: "Error!",
                                                                                         message: error,
                                                                                         inViewController: self,
                                                                                         actionButtonTitle: "Ok",
                                                                                         actionHandler: nil)
        })
    }
    
    @IBAction func dissmissView(_ sender: UIButton) {
        handleViewController.dismiss(animated: true,
                                     completion: nil)
    }
    
    //MARK: Text Field Delegate
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if typeOfEdit == .birthday && textField.tag == 13 {
            let inputView = UIView(frame: CGRect(x: 0,
                                                 y: 0,
                                                 width: self.view.frame.width,
                                                 height: 240))
            let datePickerView: UIDatePicker = UIDatePicker(frame: CGRect(x: 0,
                                                                          y: 40,
                                                                          width: 0,
                                                                          height: 0))
            datePickerView.locale = Locale(identifier: "en_US_POSIX")
            datePickerView.timeZone = TimeZone(secondsFromGMT: 0)
            
            datePickerView.maximumDate = Date()
            if let birthday = DataStorage.shared.activeUser.birthday {
                datePickerView.date = birthday
            } else {
                datePickerView.date = dateFormatter.date(from: "Jan 1, 1985")!
            }
            
            datePickerView.datePickerMode = .date
            inputView.addSubview(datePickerView) // add date picker to UIView
            
            let doneButton = UIButton(frame: CGRect(x: self.view.frame.size.width - 100,
                                                    y: 0,
                                                    width: 100,
                                                    height: 50))
            doneButton.setTitle("Done",
                                for: .normal)
            doneButton.setTitleColor(UIColor.black,
                                     for: .normal)
            doneButton.setTitleColor(UIColor.gray,
                                     for: .highlighted)
            inputView.addSubview(doneButton)
            doneButton.addTarget(self,
                                 action: #selector(dismissPicker),
                                 for: .touchUpInside)
            textField.inputView = inputView
            datePickerView.addTarget(self,
                                     action: #selector(datePickerValueChanged),
                                     for: .valueChanged)
            
            self.datePickerValueChanged(sender: datePickerView)
        }
        return true
    }
    
    func datePickerValueChanged(sender: UIDatePicker) {
        newDetailItemTextField.text = dateFormatter.string(from: sender.date)
    }
    
    func dismissPicker() {
        _ = textFieldShouldReturn(newDetailItemTextField)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //MARK: Table View Data Source 
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        switch typeOfEdit {
        case .firstName, .lastName:
            return 2
        default:
            return 3
        }
    }
}
