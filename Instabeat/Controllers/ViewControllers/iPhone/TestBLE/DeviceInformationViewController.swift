//
//  DeviceInformationViewController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 10/7/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit

class DeviceInformationViewController: UIViewController, PeripheralCharacteristicUpdateDelegate {
    @IBOutlet weak var manufacturerNameLabel: UILabel!
    @IBOutlet weak var hardwareRevisionLabel: UILabel!
    @IBOutlet weak var serialNumberLabel: UILabel!

    public var manufacturerNameString: String?
    public var hardwareRevisionString: String?
    public var serialNumberString: String?
    
    override func viewDidLoad() {
        manufacturerNameLabel.text = manufacturerNameString
        hardwareRevisionLabel.text = hardwareRevisionString
        serialNumberLabel.text = serialNumberString
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIHelper.restrictRotation(restrict: true)
        if UIApplication.shared.statusBarOrientation != .portrait {
            let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
        }
        CentralBuetoothManager.shared.characteristicUpdateDelegate = self
    }
    
    // MARK: Peripheral characteristic update delegate
    func update(deviceInfo: String) {
        manufacturerNameLabel.text = deviceInfo
    }
    
    func update(hardwareRevision: String) {
        hardwareRevisionLabel.text = hardwareRevision
    }
    
    func update(serialNumber: String) {
        serialNumberLabel.text = serialNumber
    }
}
