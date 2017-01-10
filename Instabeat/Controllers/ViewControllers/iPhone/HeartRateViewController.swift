//
//  HeartRateViewController.swift
//  Instabeat
//
//  Created by Dmytro on 4/25/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit

class HeartRateViewController: UIViewController,  PeripheralCharacteristicUpdateDelegate {

    @IBOutlet weak var heartbeatRateLabel: UILabel!
        
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
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
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIHelper.dismissHUD()
        CentralBuetoothManager.shared.stopScan()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Peripheral characteristic update delegate
    func update(heartBeatRate: Int) {
        if heartBeatRate == 0 {
            heartbeatRateLabel.text = "--"
        }
        else {
            heartbeatRateLabel.text = "\(heartBeatRate)"
        }
    }
    
    func delay(delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            closure()
        }
    }
}
