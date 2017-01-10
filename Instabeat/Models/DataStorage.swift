//
//  DataStorage.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 11/11/16.
//  Copyright © 2016 GL. All rights reserved.
//

import Foundation

class DataStorage {
    var activeUser = User() 
    var connectedPeripheral: ConnectedPeripheral = ConnectedPeripheral()
    static let shared = DataStorage()
}
