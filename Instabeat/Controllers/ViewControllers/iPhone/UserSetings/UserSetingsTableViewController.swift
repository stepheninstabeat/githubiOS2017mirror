//
//  UserSetingsTableViewController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 11/24/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import CoreBluetooth
import STZPopupView
import FacebookCore
import FacebookLogin
import GoogleSignIn

class UserSetingsTableViewController: UITableViewController, UITextFieldDelegate, ConnectionManagerDelegate, PeripheralCharacteristicUpdateDelegate, UIViewControllerTransitioningDelegate {
    
    @IBOutlet weak var restingBPMTextField: UITextField!
    @IBOutlet weak var fatBurningZoneMiddleValue: UITextField!
    @IBOutlet weak var fatBurningZoneMaximumValue: UITextField!
    @IBOutlet weak var fitnessZoneMiddleValue: UITextField!
    @IBOutlet weak var fitnessZoneMaximumValue: UITextField!
    @IBOutlet weak var maximumPerformanceMiddleValue: UITextField!
    @IBOutlet weak var maximumPerformanceMaximumValue: UITextField!
    @IBOutlet weak var firmwareVersionLabel: UILabel!
    @IBOutlet weak var hardwareVersionLabel: UILabel!
    @IBOutlet weak var updateFirmwareVersionButton: UIButton!
    @IBOutlet weak var linkDeviceButton: UIButton!
    @IBOutlet weak var batteryStatusLabel: UILabel!
    @IBOutlet weak var LEDBrightnessSlider: UISlider!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var userDayOfBirthLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    
    private var textFieldsArray: [UITextField]!
    private var activeTextField: UITextField?
    private var searchDeviceViewController: SearchDeviceTableViewController!
    private var isPresentedSearchView = false
    private let dateFormatter = DateFormatter()
    private var titlesForSection: [String]!
    private var requestTimer: Timer!
    private var oldText: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIHelper.restrictRotation(restrict: true)
        titlesForSection = [
            "BODY STATISTICS",
            "DEVICE SETTINGS",
            "ACCOUNT SETTINGS"
        ]
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.none
        
        CentralBuetoothManager.shared.connectionManagerDelegate = self
        CentralBuetoothManager.shared.characteristicUpdateDelegate = self
        
        textFieldsArray = [
            restingBPMTextField,
            fatBurningZoneMiddleValue,
            fatBurningZoneMaximumValue,
            fitnessZoneMiddleValue,
            fitnessZoneMaximumValue,
            maximumPerformanceMiddleValue,
            maximumPerformanceMaximumValue,
        ]
        
        if CentralBuetoothManager.shared.isDeviceConnected {
            batteryStatusLabel.text = DataStorage.shared.connectedPeripheral.batteryStatus
            firmwareVersionLabel.text = DataStorage.shared.connectedPeripheral.firmwareVersion
            hardwareVersionLabel.text = DataStorage.shared.connectedPeripheral.hardwareRevision
        } else {
            resetLabels()
        }
        tableView.backgroundColor = Constants.primaryColors.mediumGreyColor
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateUserInformation),
                                               name:  NSNotification.Name(rawValue: "updateUserInformation"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(calculateHRZones),
                                               name: NSNotification.Name(rawValue: "BirthdayUpdated"),
                                               object: nil)
        updateUserInformation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIHelper.dismissHUD()
        CentralBuetoothManager.shared.stopScan()
    }
    
    func updateUserInformation() {
        userEmailLabel.text = DataStorage.shared.activeUser.email
        usernameLabel.text  = DataStorage.shared.activeUser.firstName
        if let birthday = DataStorage.shared.activeUser.birthday {
            userDayOfBirthLabel.text = dateFormatter.string(from: birthday)
        } else {
            userDayOfBirthLabel.text = "Day Of Birth is not specified"
        }
        restingBPMTextField.text            = String(DataStorage.shared.activeUser.restingHR)
        fatBurningZoneMiddleValue.text      = String(DataStorage.shared.activeUser.fatBurningMiddleZone)
        fatBurningZoneMaximumValue.text     = String(DataStorage.shared.activeUser.fatBurningMaximumZone)
        fitnessZoneMiddleValue.text         = String(DataStorage.shared.activeUser.fitnessMiddleZone)
        fitnessZoneMaximumValue.text        = String(DataStorage.shared.activeUser.fitnessMaximumZone)
        maximumPerformanceMiddleValue.text  = String(DataStorage.shared.activeUser.maximumPerformanceMiddleZone)
        maximumPerformanceMaximumValue.text = String(DataStorage.shared.activeUser.maximumPerformanceMaximumZone)
        
        for textField in textFieldsArray {
            if textField.text == "0" {
                textField.text = ""
            }
        }
        updateFirmwareVersionButton.isEnabled = false
        updateFirmwareVersionButton.layer.borderColor = UIColor.gray.cgColor
        updateFirmwareVersionButton.setTitleColor(UIColor.gray, for: .normal)
        if DataStorage.shared.activeUser.instabeatHardwareVersion == "" ||
            DataStorage.shared.activeUser.instabeatHardwareVersion != CentralBuetoothManager.shared.connectedPeripheral?.identifier.uuidString {
            linkDeviceButton.setTitle("LINK",
                                      for: .normal)
        } else {
            linkDeviceButton.setTitle("UNLINK",
                                      for: .normal)
        }
    }
    
    @IBAction func linkDevice(_ sender: UIButton) {
        CentralBuetoothManager.shared.cancelConnection()
        if sender.titleLabel?.text == "LINK" {
            if let hardwareRevision = CentralBuetoothManager.shared.connectedPeripheral?.identifier.uuidString {
                NetworkManager.shared.linkIBDevice(hardwareID: hardwareRevision,
                                                   firmwareID: DataStorage.shared.connectedPeripheral.firmwareVersion,
                                                   successHandler: { user in
                                                    DataStorage.shared.activeUser.instabeatHardwareVersion = hardwareRevision
                                                    DatabaseManager.shared.save(user: user,
                                                                                failure: { error in
                                                                                    print(error)
                                                    })
                                                    UIHelper.showAlertControllerWith(title: nil,
                                                                                     message: "Your device has been successfully linked.",
                                                                                     inViewController: self,
                                                                                     actionButtonTitle: "OK",
                                                                                     actionHandler: nil)
                                                    self.linkDeviceButton.setTitle("UNLINK", for: .normal)
                },
                                                   failureHandler: { error in
                                                    UIHelper.showAlertControllerWith(title: nil,
                                                                                     message: error,
                                                                                     inViewController: self,
                                                                                     actionButtonTitle: "OK",
                                                                                     actionHandler: nil)
                })
            } else {
                CentralBuetoothManager.shared.scan()
            }
        } else {
            NetworkManager.shared.unlinkIBDevice(hardwareID: DataStorage.shared.activeUser.instabeatHardwareVersion,
                                                 successHandler: { user in
                                                    DatabaseManager.shared.save(user: user,
                                                                                failure: { error in
                                                                                    print(error)
                                                    })
                                                    UIHelper.showAlertControllerWith(title: nil,
                                                                                     message: "Your device has been successfully unlinked",
                                                                                     inViewController: self,
                                                                                     actionButtonTitle: "OK",
                                                                                     actionHandler: nil)
            }, failureHandler: { error in
                UIHelper.showAlertControllerWith(title: nil,
                                                 message: error,
                                                 inViewController: self,
                                                 actionButtonTitle: "OK",
                                                 actionHandler: nil)
            })
        }
        self.linkDeviceButton.setTitle("LINK",
                                       for: .normal)
    }
    
    @IBAction func syncWithDevice(_ sender: Any) {
        var sessionIDs: [String] = []
            let group = DispatchGroup()
            UIHelper.showHUDLoading()
            let sessions = [
                "session 1",
                "session 2",
                "session 3",
                "session 4",
                "session 5",
                "session 8",
                ]
            for session in sessions {
                let file = "\(session).txt" //this is the file. we will write to and read from it
                if let dir = FileManager.default.urls(for: .documentDirectory,
                                                      in: .userDomainMask).first {
                    let path = dir.appendingPathComponent(file)
                    do {
                        let data = try String(contentsOf: path,
                                              encoding: String.Encoding.utf8)
                        group.enter()
                        NetworkManager.shared.uploadUserSession(session: data,
                                                                successHandler: { (response) in
                                                                    sessionIDs.append(response)
                                                                    group.leave()
                        }, failureHandler: { error in
                            print(error)
                            group.leave()
                        })
                    }
                    catch {
                        print("error reading data")
                        group.leave()
                    }
                }
            }
            group.notify(queue: .main) {
                DataCoordinator.downloadUserSessions(userID: DataStorage.shared.activeUser.userID,
                                                     token: DataStorage.shared.activeUser.token,
                                                     sessionsIDs: sessionIDs,
                                                     completted: {
                                                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NewSessionsAvailable"),
                                                                                        object: nil)
                                                        UIHelper.dismissHUD()
                })
            }
    
    }

    //MARK: Table View Data Source
    
    override func tableView(_ tableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {
        let bundle = Bundle.main
        let nib = UINib(nibName: "UserSettingsViewForHeaderInSection",
                        bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UserSettingsViewForHeaderInSection
        view.sectionTitleLabel.text = titlesForSection[section]
        return view
    }
    
    override func tableView(_ tableView: UITableView,
                            heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }
    
    //MARK: Text Field Delegate
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        activeTextField = textField
        oldText = textField.text
        
        let keyboardDoneButtonView = UIToolbar.init()
        keyboardDoneButtonView.sizeToFit()
        let flexibleSpacing = UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace,
                                                   target: nil,
                                                   action: nil)
        let doneButton = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.done,
                                              target: self,
                                              action: #selector(doneClicked(sender:)))
        
        keyboardDoneButtonView.items = [
            flexibleSpacing,
            doneButton
        ]
        textField.inputAccessoryView = keyboardDoneButtonView
        return true
    }
    

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        guard DataStorage.shared.activeUser.age >= 0 else {
            textField.text = ""
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
            DataStorage.shared.activeUser.restingHR = restingHR
            calculateHRZones()
        case fatBurningZoneMiddleValue:
            DataStorage.shared.activeUser.fatBurningMiddleZone          = Int(fatBurningZoneMiddleValue.text!) ?? 0
        case fatBurningZoneMaximumValue:
            DataStorage.shared.activeUser.fatBurningMaximumZone         = Int(fatBurningZoneMaximumValue.text!) ?? 0
        case fitnessZoneMiddleValue:
            DataStorage.shared.activeUser.fitnessMiddleZone             = Int(fitnessZoneMiddleValue.text!) ?? 0
        case fitnessZoneMaximumValue:
            DataStorage.shared.activeUser.fitnessMaximumZone            = Int(fitnessZoneMaximumValue.text!) ?? 0
        case maximumPerformanceMiddleValue:
            DataStorage.shared.activeUser.maximumPerformanceMiddleZone  = Int(maximumPerformanceMiddleValue.text!) ?? 0
        case maximumPerformanceMaximumValue:
            DataStorage.shared.activeUser.maximumPerformanceMaximumZone = Int(maximumPerformanceMaximumValue.text!) ?? 0
        default:
            break
        }
        do {
            try DatabaseManager.shared.realm.commitWrite()
            DatabaseManager.shared.save(user: DataStorage.shared.activeUser,
                                        failure: nil)
        }
        catch (let error){ print(error.localizedDescription) }

        return true
    }
    func calculateHRZones() {
        let restingHR = DataStorage.shared.activeUser.restingHR
        let fatBurningMiddleZone            = Utility.calculate(fatBurningMiddleZone: restingHR)
        let fatBurningMaximumZone           = Utility.calculate(fatBurningMaximumZone: restingHR)
        let fitnessMiddleZone               = Utility.calculate(fitnessMiddleZone: restingHR)
        let fitnessMaximumZone              = Utility.calculate(fitnessMaximumZone: restingHR)
        let maximumPerformanceMiddleZone    = Utility.calculate(maximumPerformanceMiddleZone: restingHR)
        let maximumPerformanceMaximumZone   = Utility.calculate(maximumPerformanceMaximumZone: restingHR)
        
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
    }
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        if oldText == sender.text {
            saveButton.isHidden = true
        } else {
            saveButton.isHidden = false
        }
    }

    func validateFields() -> Bool {
        for textField in textFieldsArray {
            if textField.text?.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) != nil {
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
    
    @IBAction func saveUserInfo(_ sender: UIButton) {
        guard validateFields() else {
            return
        }
        UIHelper.showHUDLoading()
        NetworkManager.shared.updateUserInformation([
            .restingHR: DataStorage.shared.activeUser.restingHR,
            .fatBurningMiddleZone: DataStorage.shared.activeUser.fatBurningMiddleZone,
            .fatBurningMaximumZone: DataStorage.shared.activeUser.fatBurningMaximumZone,
            .fitnessMiddleZone: DataStorage.shared.activeUser.fitnessMiddleZone,
            .fitnessMaximumZone: DataStorage.shared.activeUser.fitnessMaximumZone,
            .maximumPerformanceMiddleZone: DataStorage.shared.activeUser.maximumPerformanceMiddleZone,
            .maximumPerformanceMaximumZone: DataStorage.shared.activeUser.maximumPerformanceMaximumZone
            ],
                                                    successHandler: { user in
                                                        DatabaseManager.shared.save(user: user,
                                                                                    failure: nil)
                                                        self.saveButton.isHidden = true
                                                        UIHelper.showAlertControllerWith(title: nil,
                                                                                         message: "Data has been updated successfully.",
                                                                                         inViewController: self,
                                                                                         actionButtonTitle: "OK",
                                                                                         actionHandler: nil)
        },
                                                    failureHandler: { error in
                                                        UIHelper.showAlertControllerWith(title: nil,
                                                                                         message: error,
                                                                                         inViewController: self,
                                                                                         actionButtonTitle: "OK",
                                                                                         actionHandler: nil)
        })
    }
    
    func doneClicked(sender: AnyObject) {
        _ = textFieldShouldReturn(activeTextField!)
    }
    
    @IBAction func logOutUser(_ sender: UIButton) {
        KeychainWrapper.standard.removeObject(forKey: "InstabeatUserEmail")
        KeychainWrapper.standard.removeObject(forKey: "InstabeatUserPassword")
        
        LoginManager().logOut()
        GIDSignIn.sharedInstance().signOut()
        
        DatabaseManager.shared.deleteRealm()
        DataStorage.shared.activeUser = User()
        CentralBuetoothManager.shared.cancelConnection()
        let storyboard = UIStoryboard(name: "Main",
                                      bundle: nil)
        let initialViewController: UIViewController!
        
        initialViewController = storyboard.instantiateViewController(withIdentifier: "NavLoginViewController")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = initialViewController
    }
    
    @IBAction func changeLEDBrightness(_ sender: UISlider) {
        let brightnessLevel = Float(lroundf(sender.value))
        sender.setValue(brightnessLevel,
                        animated: true)
        //TODO: sent updated LED to device if device is available
        guard CentralBuetoothManager.shared.isDeviceConnected else {
            return
        }
        
        let brightnessLevelValue: String!
        switch Int(brightnessLevel) {
        case 0:
            brightnessLevelValue = "0"
        case 1:
            brightnessLevelValue = "19"
        case 2:
            brightnessLevelValue = "32"
        case 3:
            brightnessLevelValue = "4B"
        default:
            brightnessLevelValue = "64"
        }
        let input0 = "ledb 0 \(brightnessLevelValue)"
        let input1 = "ledb 1 \(brightnessLevelValue)"
        let data0 = input0.data(using: String.Encoding.utf8)!
        let data1 = input1.data(using: String.Encoding.utf8)!
        
        CentralBuetoothManager.shared.connectedPeripheral?.writeValue(data0,
                                                                      for: CentralBuetoothManager.shared.TXCharacteristic,
                                                                      type: .withResponse)
        CentralBuetoothManager.shared.connectedPeripheral?.writeValue(data1,
                                                                      for: CentralBuetoothManager.shared.TXCharacteristic,
                                                                      type: .withResponse)
    }
    
    private func resetLabels() {
        batteryStatusLabel.text     = "N/A"
        firmwareVersionLabel.text   = "N/A"
        hardwareVersionLabel.text   = "N/A"
    }
    
    //MARK: Connection Manager Delegate
    
    func centralManagerStartDiscoveringDevices() {
        if searchDeviceViewController == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            searchDeviceViewController = storyboard.instantiateViewController(withIdentifier: "searchDeviceTabelViewController") as! SearchDeviceTableViewController
        }
        if !isPresentedSearchView {
            guard let popupView = searchDeviceViewController.view else {
                return
            }
            popupView.frame = CGRect(x: 0,
                                     y: 0,
                                     width: self.view.frame.width - 40,
                                     height: self.view.frame.height - 80)
            popupView.center = self.view.center
            
            let popupConfig = STZPopupViewConfig()
            popupConfig.dismissTouchBackground = true
            popupConfig.cornerRadius = 7
            popupConfig.showAnimation = .fadeIn
            popupConfig.dismissAnimation = .fadeOut
            popupConfig.showCompletion = { popupView in
                self.isPresentedSearchView = true
            }
            popupConfig.dismissCompletion = { popupView in
                self.isPresentedSearchView = false
                CentralBuetoothManager.shared.stopScan()
            }
            presentPopupView(popupView,
                             config: popupConfig)
        }
        searchDeviceViewController.activityIndicator.startAnimating()
        requestTimer = Timer.scheduledTimer(timeInterval: 5.0,
                                            target: self,
                                            selector: #selector(devicesNotFound),
                                            userInfo: nil,
                                            repeats: false)
    }
    
    func devicesNotFound() {
        CentralBuetoothManager.shared.stopScan()
        searchDeviceViewController.infoLabelMessage = "NO DEVICES FOUND!"
    }
    
    func centralManager(_ centralManager: CBCentralManager,
                        didDiscoverDevice peripheral: CBPeripheral) {
        requestTimer.invalidate()
        searchDeviceViewController.found(device: peripheral)
    }
    
    func centralManager(_ centralManager: CBCentralManager,
                        connectToDevice peripheral: CBPeripheral) {
        UIHelper.showHUDLoading()
    }
    
    func centralManager(_ centralManager: CBCentralManager,
                        didConnectPeripheral peripheral: CBPeripheral) {
        self.dismissPopupView()
        let hardwareRevision = peripheral.identifier.uuidString
        DataStorage.shared.connectedPeripheral.hardwareRevision = hardwareRevision
        if hardwareRevision == DataStorage.shared.activeUser.instabeatHardwareVersion {
            self.linkDeviceButton.setTitle("UNLINK",
                                           for: .normal)
        }
        else {
            NetworkManager.shared.linkIBDevice(hardwareID: hardwareRevision,
                                               firmwareID: DataStorage.shared.connectedPeripheral.firmwareVersion,
                                               successHandler: { user in
                                                
                                                DatabaseManager.shared.realm.beginWrite()
                                                DataStorage.shared.activeUser.instabeatHardwareVersion = hardwareRevision
                                                do {
                                                    try DatabaseManager.shared.realm.commitWrite()
                                                }
                                                catch (let error) { print(error.localizedDescription) }
                                                UIHelper.showAlertControllerWith(title: nil,
                                                                                 message: "Your device has been successfully linked.",
                                                                                 inViewController: self,
                                                                                 actionButtonTitle: "OK",
                                                                                 actionHandler: nil)
                                                self.linkDeviceButton.setTitle("UNLINK", for: .normal)
            },
                                               failureHandler: { error in
                                                UIHelper.showAlertControllerWith(title: nil,
                                                                                 message: error,
                                                                                 inViewController: self,
                                                                                 actionButtonTitle: "OK",
                                                                                 actionHandler: nil)
            })
        }
        
    }
    
    func centralManager(_ centralManager: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral) {
        resetLabels()
        self.tableView.reloadData()
    }
    
    //MARK: Peripheral characteristic update delegate
    func update(batteryLevel: Int) {
        batteryStatusLabel.text = DataStorage.shared.connectedPeripheral.batteryStatus
    }
    
    func update(firmwareVersion: String) {
        firmwareVersionLabel.text = firmwareVersion
        DataStorage.shared.connectedPeripheral.firmwareVersion = firmwareVersion
        NetworkManager.shared.updateUserInformation([
            .instabeatFirmwareVersion: firmwareVersion
            ],
                                                    successHandler: nil,
                                                    failureHandler: nil)
    }
    
    func update(hardwareRevision: String) {
        hardwareVersionLabel.text = hardwareRevision
    }
    
    //MARK: Change User Details
    
    @IBAction func changeUserDetail(_ sender: UIButton) {
        let viewController = self.storyboard!.instantiateViewController(withIdentifier: "changeUserDetailsNavigationController") as! UINavigationController
        let tableViewController = viewController.viewControllers.first! as! EditUserDetailsTableViewController
        tableViewController.handleViewController = self
        switch sender.tag {
        case 0:
            tableViewController.typeOfEdit = .firstName
        case 1:
            tableViewController.typeOfEdit = .email
        case 2:
            tableViewController.typeOfEdit = .birthday
        default:
            tableViewController.typeOfEdit = .password
        }
        viewController.modalPresentationStyle = UIModalPresentationStyle.custom
        viewController.transitioningDelegate = self
        
        self.present(viewController,
                     animated: true,
                     completion: nil)
    }
    
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        let presentationController = EditUserUIPresentationController(presentedViewController: presented,
                                                                      presenting: presenting)
        return presentationController
    }
    
}
