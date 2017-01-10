//
//  BPMCalculationViewController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 11/2/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit

class BPMCalculationViewController: UITableViewController, UITextFieldDelegate {
    @IBOutlet weak var birthdayTextField: UITextField!
    @IBOutlet weak var restingBPMTextField: UITextField!
    @IBOutlet weak var fatBurningZoneMiddleValue: UITextField!
    @IBOutlet weak var fatBurningZoneMaximumValue: UITextField!
    @IBOutlet weak var fitnessZoneMiddleValue: UITextField!
    @IBOutlet weak var fitnessZoneMaximumValue: UITextField!
    @IBOutlet weak var maximumPerformanceMiddleValue: UITextField!
    @IBOutlet weak var maximumPerformanceMaximumValue: UITextField!
    
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet var letsDiveInView: UIView!
    @IBOutlet var tableHeaderView: UIView!
    private var activeTextField: UITextField?
    private var textFieldsArray: [UITextField]!
    private let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true,
                                               animated: false)
        self.view.backgroundColor = Constants.primaryColors.yellowColor
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.none
        textFieldsArray = [
            birthdayTextField,
            restingBPMTextField,
            fatBurningZoneMiddleValue,
            fatBurningZoneMaximumValue,
            fitnessZoneMiddleValue,
            fitnessZoneMaximumValue,
            maximumPerformanceMiddleValue,
            maximumPerformanceMaximumValue
        ]
        
        tableView.tableHeaderView = tableHeaderView
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeHeaderToFit()
    }
    
    private func sizeHeaderToFit() {
        if let headerView = tableView.tableHeaderView {
            
            headerView.setNeedsLayout()
            headerView.layoutIfNeeded()
            
            let height: CGFloat = 126
            var newFrame = headerView.frame
            
            // Needed or we will stay in viewDidLayoutSubviews() forever
            if height != newFrame.size.height {
                newFrame.size.height = height
                headerView.frame = newFrame
                
                tableView.tableHeaderView = headerView
            }
        }
    }
    
    // MARK: Skip On Boarding
    
    @IBAction func skipOnBoarding(_ sender: Any) {
        let skipOnBoardingAlert = UIAlertController(title: nil,
                                                    message: "Are you sure that you want to skip this step? You can link your Instabeat later.",
                                                    preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "OK",
                                       style: .default,
                                       handler: {(action) in
                                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SkipOnBoarding"),
                                                                        
                                                                        object: nil)
        })
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .default,
                                         handler: nil)
        
        skipOnBoardingAlert.addAction(okayAction)
        skipOnBoardingAlert.addAction(cancelAction)
        
        self.present(skipOnBoardingAlert,
                     animated: true,
                     completion: nil)
        
    }
    
    // MARK: Text Field Delegate
    @IBAction func textFieldEditing(_ sender: UITextField) {
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
        if !(sender.text?.isEmpty)! {
            datePickerView.date = dateFormatter.date(from: sender.text!)!
        } else {
            datePickerView.date = dateFormatter.date(from: "Jan 1, 1985")!
        }
        datePickerView.datePickerMode = UIDatePickerMode.date
        inputView.addSubview(datePickerView) // add date picker to UIView
        
        let doneButton = UIButton(frame: CGRect(x: self.view.frame.size.width - 100,
                                                y: 0,
                                                width: 100,
                                                height: 50))
        doneButton.setTitle("Done",
                            for: UIControlState.normal)
        doneButton.setTitleColor(UIColor.black,
                                 for: UIControlState.normal)
        doneButton.setTitleColor(UIColor.gray,
                                 for: UIControlState.highlighted)
        
        inputView.addSubview(doneButton)
        
        doneButton.addTarget(self,
                             action: #selector(dismissPicker),
                             for: UIControlEvents.touchUpInside)
        
        sender.inputView = inputView
        datePickerView.addTarget(self,
                                 action: #selector(datePickerValueChanged),
                                 for: UIControlEvents.valueChanged)
        
        self.datePickerValueChanged(sender: datePickerView)
    }
    
    func datePickerValueChanged(sender:UIDatePicker) {
        birthdayTextField.text = dateFormatter.string(from: sender.date)
        DataStorage.shared.activeUser.birthday = sender.date
    }
    
    func dismissPicker() {
        _ = textFieldShouldReturn(birthdayTextField)
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        activeTextField = textField
        if textField != birthdayTextField {
            let keyboardDoneButtonView = UIToolbar.init()
            keyboardDoneButtonView.sizeToFit()
            let flexibleSpacing = UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace,
                                                       target: nil,
                                                       action: nil)
            let doneButton = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.done,
                                                  target: self,
                                                  action: #selector(doneClicked(sender:)))
            
            keyboardDoneButtonView.items = [flexibleSpacing, doneButton]
            textField.inputAccessoryView = keyboardDoneButtonView
        }
        return true
    }
    
    func doneClicked(sender: AnyObject) {
        _ = textFieldShouldReturn(activeTextField!)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if textField != birthdayTextField {
            guard !(textField.text?.isEmpty)! else {
                UIHelper.showAlertControllerWith(title: "Error",
                                                 message: "One or more fields are empty!",
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
                return true
            }
            guard textField.text?.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil else {
                UIHelper.showAlertControllerWith(title: "Error",
                                                 message: "Only digits allowed for HR!",
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
                return true
            }
            guard DataStorage.shared.activeUser.age > 0 else {
                UIHelper.showAlertControllerWith(title: "Error",
                                                 message: "Plesase update your Day Of Birth to complete with Hear Rate Calculation",
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
                return true
            }
            
            DatabaseManager.shared.realm.beginWrite()
            switch textField {
            case restingBPMTextField:
                let restingHR = Int(textField.text!)!
                
                let fatBurningMiddleZone            = Utility.calculate(fatBurningMiddleZone: restingHR)
                let fatBurningMaximumZone           = Utility.calculate(fatBurningMaximumZone: restingHR)
                let fitnessMiddleZone               = Utility.calculate(fitnessMiddleZone: restingHR)
                let fitnessMaximumZone              = Utility.calculate(fitnessMaximumZone:restingHR)
                let maximumPerformanceMiddleZone    = Utility.calculate(maximumPerformanceMiddleZone:restingHR)
                let maximumPerformanceMaximumZone   = Utility.calculate(maximumPerformanceMaximumZone:restingHR)
                
                DataStorage.shared.activeUser.restingHR                     = restingHR
                DataStorage.shared.activeUser.fatBurningMiddleZone          = fatBurningMiddleZone
                DataStorage.shared.activeUser.fatBurningMaximumZone         = fatBurningMaximumZone
                DataStorage.shared.activeUser.fitnessMiddleZone             = fitnessMiddleZone
                DataStorage.shared.activeUser.fitnessMaximumZone            = fitnessMaximumZone
                DataStorage.shared.activeUser.maximumPerformanceMiddleZone  = maximumPerformanceMiddleZone
                DataStorage.shared.activeUser.maximumPerformanceMaximumZone = maximumPerformanceMaximumZone
                
                fatBurningZoneMiddleValue.text      = String(fatBurningMiddleZone)
                fatBurningZoneMaximumValue.text     = String(fatBurningMaximumZone)
                fitnessZoneMiddleValue.text         = String(fitnessMiddleZone)
                fitnessZoneMaximumValue.text        = String(fitnessMaximumZone)
                maximumPerformanceMiddleValue.text  = String(maximumPerformanceMiddleZone)
                maximumPerformanceMaximumValue.text = String(maximumPerformanceMaximumZone)
                
            case fatBurningZoneMiddleValue:
                DataStorage.shared.activeUser.fatBurningMiddleZone          = Int(fatBurningZoneMiddleValue.text!)!
            case fatBurningZoneMaximumValue:
                DataStorage.shared.activeUser.fatBurningMaximumZone         = Int(fatBurningZoneMaximumValue.text!)!
            case fitnessZoneMiddleValue:
                DataStorage.shared.activeUser.fitnessMiddleZone             = Int(fitnessZoneMiddleValue.text!)!
            case fitnessZoneMaximumValue:
                DataStorage.shared.activeUser.fitnessMaximumZone            = Int(fitnessZoneMaximumValue.text!)!
            case maximumPerformanceMiddleValue:
                DataStorage.shared.activeUser.maximumPerformanceMiddleZone  = Int(maximumPerformanceMiddleValue.text!)!
            case maximumPerformanceMaximumValue:
                DataStorage.shared.activeUser.maximumPerformanceMaximumZone = Int(maximumPerformanceMaximumValue.text!)!
            default:
                break
            }
        }
        do {
            try DatabaseManager.shared.realm.commitWrite()
            DatabaseManager.shared.save(user: DataStorage.shared.activeUser,
                                        failure: nil)
        }
        catch (let error) { print(error.localizedDescription) }
        return true
    }
    
    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        activeTextField?.resignFirstResponder()
    }
    @IBAction func goToNextViewController(_ sender: Any) {
        view.endEditing(true)
        if (birthdayTextField.text?.isEmpty)! {
            UIHelper.showAlertControllerWith(title: "Sign Up Failed",
                                             message: "Date of Birth field cannot be empty.",
                                             inViewController: self,
                                             actionButtonTitle: "OK",
                                             actionHandler: nil)
            return
        }
        guard validateFields() else {
            return
        }
        //TODO: sent user object to request instead of differents fields
        
        let birthdayDate = dateFormatter.date(from: birthdayTextField.text!)
        NetworkManager.shared.updateUserInformation([
            .restingHR: DataStorage.shared.activeUser.restingHR,
            .fatBurningMiddleZone: DataStorage.shared.activeUser.fatBurningMiddleZone,
            .fatBurningMaximumZone: DataStorage.shared.activeUser.fatBurningMaximumZone,
            .fitnessMiddleZone: DataStorage.shared.activeUser.fitnessMiddleZone,
            .fitnessMaximumZone: DataStorage.shared.activeUser.fitnessMaximumZone,
            .maximumPerformanceMiddleZone: DataStorage.shared.activeUser.maximumPerformanceMiddleZone,
            .maximumPerformanceMaximumZone: DataStorage.shared.activeUser.maximumPerformanceMaximumZone,
            .birthday : (birthdayDate?.iso8601)!,
            ],
                                                    
                                                    successHandler: { (user) in
                                                        
        },
                                                    failureHandler: { (error) in
                                                        print("Error!!")
        })
        UIView.transition(with: UIApplication.shared.keyWindow!,
                          duration: 2.5,
                          options: .curveEaseOut,
                          animations: {
                            self.letsDiveInView.frame = UIScreen.main.bounds
                            UIApplication.shared.keyWindow?.addSubview(self.letsDiveInView)
        },
                          completion: { finished in
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let initialViewController: UIViewController!
                            initialViewController = storyboard.instantiateViewController(withIdentifier: "TabBarViewController")
                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                            appDelegate.window?.rootViewController = initialViewController
        })
        
    }
    
    func validateFields() -> Bool {
        for textField in textFieldsArray {
            if textField.text?.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) != nil && textField != birthdayTextField {
                UIHelper.showAlertControllerWith(title: "Error",
                                                 message: "Only digits allowed for HR",
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
                return false
            }
            if textField == restingBPMTextField, let restingHRText = textField.text, let restingHR = Int(restingHRText) {
                guard (30...120).contains(restingHR) else {
                    UIHelper.showAlertControllerWith(title: "Error",
                                                     message: "Please enter a value between 30 and 120 bpm",
                                                     inViewController: self,
                                                     actionButtonTitle: "OK",
                                                     actionHandler: nil)
                    return false
                }
            }
            if (textField.text?.isEmpty)! {
                UIHelper.showAlertControllerWith(title: "Error",
                                                 message: "Some text field is empty",
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
                return false
            }
        }
        return true
    }
}

