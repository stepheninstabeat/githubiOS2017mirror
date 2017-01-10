//
//  SynchronisatioViewController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 10/12/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit

class SynchronisatioViewController: UIViewController {
    
    @IBOutlet weak var synchronisationProgressView: UIProgressView!
    @IBOutlet weak var timeLeftLabel: UILabel!
    @IBOutlet weak var synchronisationPercentDoneLabel: UILabel!
    @IBOutlet weak var startSynchronisationButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    @IBAction func startSynchronisation(_ sender: AnyObject) {
        
        let input = "xbd"
        
        let data = input.data(using: String.Encoding.utf8)!
        CentralBuetoothManager.shared.connectedPeripheral?.writeValue(data,
                                                                      for: CentralBuetoothManager.shared.TXCharacteristic,
                                                                      type: .withResponse)
    }
}
