//
//  SetupLEDViewController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 10/7/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit

class SetupLEDViewController: UIViewController {
    override func viewDidLoad() {
    }
    
    @IBOutlet weak var settingsTextField: UITextField!
    @IBOutlet weak var brightnessTextField: UITextField!
    
    
    @IBAction func sentSettings(_ sender: AnyObject) {
        let input = "led " + settingsTextField.text!
        let data = input.data(using: String.Encoding.utf8)!
        CentralBuetoothManager.shared.connectedPeripheral?.writeValue(data, for: CentralBuetoothManager.shared.TXCharacteristic, type: .withResponse)
    }
    @IBAction func setBrightness(_ sender: AnyObject) {
        let input = "ledb " + brightnessTextField.text!
        let data = input.data(using: String.Encoding.utf8)!
        CentralBuetoothManager.shared.connectedPeripheral?.writeValue(data, for: CentralBuetoothManager.shared.TXCharacteristic, type: .withResponse)
    }
}
