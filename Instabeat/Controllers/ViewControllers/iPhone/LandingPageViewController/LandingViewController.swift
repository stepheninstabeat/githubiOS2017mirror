//
//  LandingViewController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 10/28/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit
import CoreBluetooth

class LandingViewController: UIViewController, ConnectionManagerDelegate, PeripheralCharacteristicUpdateDelegate {
    
    var searchDeviceViewController: SearchDeviceTableViewController!
    
    @IBOutlet weak var infoLabel1: UILabel!
    @IBOutlet weak var infoLabel2: UILabel!
    
    private var requestTimer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        CentralBuetoothManager.shared.connectionManagerDelegate = self
        CentralBuetoothManager.shared.characteristicUpdateDelegate = self
        CentralBuetoothManager.shared.scan()
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(color: Constants.primaryColors.yellowColor),
                                                               for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.view.backgroundColor = Constants.primaryColors.yellowColor
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        CentralBuetoothManager.shared.stopScan()
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
                                         style: .cancel,
                                         handler: nil)
        
        skipOnBoardingAlert.addAction(okayAction)
        skipOnBoardingAlert.addAction(cancelAction)
        
        self.present(skipOnBoardingAlert,
                     animated: true,
                     completion: nil)
    }
    
    // MARK:Connection manager delegate
    func centralManagerStartDiscoveringDevices() {
         requestTimer = Timer.scheduledTimer(timeInterval: 60.0,
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
                        connectToDevice peripheral: CBPeripheral) {
        UIHelper.showHUDLoading()
        NetworkManager.shared.linkIBDevice(hardwareID: peripheral.identifier.uuidString,
                                           firmwareID: DataStorage.shared.connectedPeripheral.firmwareVersion,
                                           successHandler: { user in
                                            DataStorage.shared.activeUser = user
        },
                                           failureHandler: { error in
                                            UIHelper.showAlertControllerWith(title: nil,
                                                                             message:error,
                                                                             inViewController: self,
                                                                             actionButtonTitle: "OK",
                                                                             actionHandler: nil)
        })
    }
    
    func centralManager(_ centralManager: CBCentralManager,
                        didConnectPeripheral peripheral: CBPeripheral) {
        searchDeviceViewController.view.isUserInteractionEnabled = false
        searchDeviceViewController.view.alpha = 0.0
        
        self.performSegue(withIdentifier: "showBPMCalculationViewController",
                          sender: self)
    }
    
    func connectionDidTimeout(peripheral: CBPeripheral) {
        CentralBuetoothManager.shared.centralManager(connectPeripheral:peripheral,
                                                     timeOut: 15.0)
    }
    
    func centralManager(_ centralManager: CBCentralManager,
                        didDiscoverDevice peripheral: CBPeripheral) {
        requestTimer.invalidate()
        searchDeviceViewController.found(device: peripheral)
    }
    
    
    func centralManagerDidUpdatedState(_ state: Int) {
        switch state {
        case 5: //CBCentralManagerState.poweredOn:
            searchDeviceViewController.infoLabelMessage = "PLEASE SELECT YOUR DEVICE"
        default:
            searchDeviceViewController.infoLabelMessage = "YOUR BLUETOOTH IS OFF!"
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {
        switch segue.identifier! {
        case "searchDeviceSegue":
            searchDeviceViewController = segue.destination as! SearchDeviceTableViewController
        default:
            break
        }
    }
}
