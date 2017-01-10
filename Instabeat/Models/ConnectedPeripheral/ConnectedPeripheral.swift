//
//  ConnectedPeripheral.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 11/30/16.
//  Copyright © 2016 GL. All rights reserved.
//

import Foundation

struct ConnectedPeripheral {
    var manufacturerName = "N/A"
    var hardwareRevision = "N/A"
    var serialNumber = "N/A"
    var firmwareVersion = "N/A"
    var batteryStatus: String = "N/A" {
        didSet {
            if Int(batteryStatus)! >= 0 {
                batteryStatus += "%"
            }
        }
    }
}
