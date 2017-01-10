//
//  TestBLETableViewController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 10/3/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit
import CoreBluetooth
import STZPopupView

class TestBLETableViewController: UITableViewController, ConnectionManagerDelegate, PeripheralCharacteristicUpdateDelegate {
    
    @IBOutlet weak var connectedDeviceLabel: UILabel!
    @IBOutlet weak var searchDevices: UIButton!
    @IBOutlet weak var batteryLevelLable: UILabel!
    @IBOutlet weak var firmwareVersionLabel: UILabel!
    public var manufacturerNameString: String?
    public var hardwareRevisionString: String?
    public var serialNumberString: String?
    
    var searchDeviceViewController: SearchDeviceTableViewController!
    var isPresentedSearchView = false
    
    override func viewDidLoad() {
        CentralBuetoothManager.shared.connectionManagerDelegate = self
        CentralBuetoothManager.shared.characteristicUpdateDelegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIHelper.dismissHUD()
        CentralBuetoothManager.shared.stopScan()
    }
    
    // MARK:Connection manager delegate
    func centralManager(_ centralManager: CBCentralManager,
                        connectionToDeviceFailed peripheral: CBPeripheral) {
        UIHelper.showAlertControllerWith(title: "Error",
                                         message: "Connection failed",
                                         inViewController: self,
                                         actionButtonTitle: "OK",
                                         actionHandler: nil)
        //        UIHelper.showErrorHUDWithStatus(error: "Connection failed")
    }
    func centralManager(_ centralManager: CBCentralManager,
                        connectionDidTimeout peripheral: CBPeripheral) {
        UIHelper.showAlertControllerWith(title: "Error",
                                         message: "Device connection timeout",
                                         inViewController: self,
                                         actionButtonTitle: "OK",
                                         actionHandler: nil)
        
        //        UIHelper.showErrorHUDWithStatus(error: "Device connection timeout")
    }
    func centralManager(_ centralManager: CBCentralManager,
                        didConnectPeripheral peripheral: CBPeripheral) {
        //        UIHelper.showSuccessHUDWithStatus(status: "Connected!")
        searchDevices.titleLabel?.text = "Disconnect"
        connectedDeviceLabel.text = "Connected device: " + peripheral.name!
        self.dismissPopupView()
    }
    func centralManager(_ centralManager: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral) {
        //        UIHelper.showErrorHUDWithStatus(error: "Disconnected!")
        connectedDeviceLabel.text = "Connected device: unavailable"
        batteryLevelLable.text = "Battery level: unavailable"
        firmwareVersionLabel.text = "Firmware version: unavailable"
        searchDevices.titleLabel?.text = "Devices"
        //        Utility.delay(delay: 0.8) {
        //            CentralBuetoothManager.sharedManager.scan()
        //        }
    }
    
    func centralManager(_ centralManager: CBCentralManager,
                        connectionToDeviceTimeout peripheral: CBPeripheral) {
        UIHelper.showAlertControllerWith(title: "Error",
                                         message: "",
                                         inViewController: self,
                                         actionButtonTitle: "OK",
                                         actionHandler: {
                                            UIHelper.showHUDLoading()
                                            CentralBuetoothManager.shared.centralManager(connectPeripheral:peripheral,
                                                                                         timeOut: 15.0)
                                         })
        //        UIHelper.showErrorHUDWithStatus(error: "Device connection timeout")
    }
    func centralManagerStartDiscoveringDevices() {
        UIHelper.showHUDLoading()
    }
    func centralManager(_ centralManager: CBCentralManager,
                        didDiscoverDevice peripheral: CBPeripheral) {
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
        searchDeviceViewController.found(device: peripheral)
        UIHelper.dismissHUD()
    }
    
    @IBAction func searchDevices(_ sender: UIButton) {
        
        if CentralBuetoothManager.shared.isDeviceConnected {
            CentralBuetoothManager.shared.cancelConnection()
        }
        else {
            searchDeviceViewController = self.storyboard?.instantiateViewController(withIdentifier: "searchDeviceTabelViewController") as! SearchDeviceTableViewController
            CentralBuetoothManager.shared.scan()
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "openDeviceInfo":
            let deviceInfoVC = segue.destination as! DeviceInformationViewController
            deviceInfoVC.hardwareRevisionString = hardwareRevisionString
            deviceInfoVC.manufacturerNameString = manufacturerNameString
            deviceInfoVC.serialNumberString = serialNumberString
        default:
            break
        }
    }
    
    //MARK: Peripheral characteristic update delegate
    func update(batteryLevel: Int) {
        batteryLevelLable.text = "Battery level: " + String(batteryLevel) + "%"
    }
    
    func update(firmwareVersion: String) {
        firmwareVersionLabel.text = "Firmware version: " + firmwareVersion
    }
    func update(deviceInfo: String) {
        manufacturerNameString = deviceInfo
    }
    
    func update(hardwareRevision: String) {
        hardwareRevisionString = hardwareRevision
    }
    func update(serialNumber: String) {
        serialNumberString = serialNumber
    }
}
