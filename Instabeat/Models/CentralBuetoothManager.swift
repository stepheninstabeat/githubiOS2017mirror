//
//  CentralBuetoothManager.swift
//  Instabeat
//
//  Created by Dmytro on 4/29/16.
//  Copyright © 2016 GL. All rights reserved.
//

import Foundation
import CoreBluetooth

//TODO: extenptions way to create delegate

protocol ConnectionManagerDelegate {
    func centralManagerDidUpdatedState(_ state: Int)
    
    func centralManagerStartDiscoveringDevices()
    
    func centralManager(_ centralManager: CBCentralManager,
                        didDiscoverDevice peripheral: CBPeripheral)
    
    func centralManager(_ centralManager: CBCentralManager,
                        connectToDevice peripheral: CBPeripheral)
    
    func centralManager(_ centralManager: CBCentralManager,
                        lostDeviceConnection peripheral: CBPeripheral)
    
    func centralManager(_ centralManager: CBCentralManager,
                        connectionDidTimeout peripheral: CBPeripheral)
    
    func centralManager(_ centralManager: CBCentralManager,
                        didConnectPeripheral peripheral: CBPeripheral)
    
    func centralManager(_ centralManager: CBCentralManager,
                        connectionToDeviceFailed peripheral: CBPeripheral)
    
    func centralManager(_ centralManager: CBCentralManager,
                        connectionToDeviceTimeout peripheral: CBPeripheral)
    
    func centralManager(_ centralManager: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral)
}

protocol PeripheralCharacteristicUpdateDelegate {
    
    func update(heartBeatRate: Int)
    
    func update(batteryLevel: Int)
    
    func update(deviceInfo: String)
    
    func update(firmwareVersion: String)
    
    func update(hardwareRevision: String)
    
    func update(serialNumber: String)
}

class CentralBuetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var connectionManagerDelegate: ConnectionManagerDelegate?
    var characteristicUpdateDelegate: PeripheralCharacteristicUpdateDelegate?
    
    static let shared = CentralBuetoothManager()
    
    var centralManager: CBCentralManager!
    public var connectedPeripheral: CBPeripheral? {
        willSet {
            if newValue == nil {
                DataStorage.shared.connectedPeripheral = ConnectedPeripheral()
            }
        }
    }
    var connectionLost = false
    var isCentralManagerReady = false
    var discoveredDevices: [CBPeripheral] = []
    var timersForPeripherals: [Timer] = []
    var connectionTimeoutTimer: Timer?
    var connectionTimer: Timer?
    private var shouldScan = false
    var isDeviceConnected = false
    
    var TXCharacteristic: CBCharacteristic!
    var RXCharacteristic: CBCharacteristic!
    
    var data = Data()
    
    //MARK:Central Manager Delegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        connectionManagerDelegate?.centralManagerDidUpdatedState(central.state.rawValue)
        guard central.state  == .poweredOn else {
            isCentralManagerReady = false
            stopScan()
            discoveredDevices.removeAll()
            timersForPeripherals.removeAll()
            
            return
        }
        isCentralManagerReady = true
        if shouldScan {
            scan()
        }
    }
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        if connectedPeripheral != peripheral {
            if peripheral.name != nil, DataStorage.shared.activeUser.instabeatHardwareVersion == "" {
                connectionManagerDelegate?.centralManager(centralManager,
                                                          didDiscoverDevice: peripheral)
            } else if DataStorage.shared.activeUser.instabeatHardwareVersion == peripheral.identifier.uuidString {
                self.centralManager(connectPeripheral: peripheral,
                                    timeOut: 15.0)
                
            }
        }
    }
    func centralManager(connectPeripheral peripheral: CBPeripheral,
                        timeOut: Double) {
        centralManager?.connect(peripheral,
                                options: [CBConnectPeripheralOptionNotifyOnConnectionKey: true])
        if timeOut > 0 {
            connectionTimeoutTimer = Timer.scheduledTimer(timeInterval: timeOut,
                                                          target: self,
                                                          selector:#selector(connectionTimeoutTimerDidFire(timer:)),
                                                          userInfo: ["peripheral":peripheral],
                                                          repeats: false)
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        cleanup()
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        
        // Stop the connection timer because we made a successful connection already
        connectionTimeoutTimer?.invalidate()
        
        // Set the flag to show we have a connection and have not yet lost it
        connectionLost = false
        
        // Stop scanning for more peripherals
        centralManager?.stopScan()
        
        shouldScan = false
        
        //Make sure we get the discovery callbacks here
        peripheral.delegate = self
        
//        [BLEServices.battery,
//         BLEServices.deviceInformation,
//         BLEServices.hearRate]
        isDeviceConnected = true
        connectionManagerDelegate?.centralManager(centralManager,
                                                  didConnectPeripheral: peripheral)
        print("centralManager didConnect peripheral")
        
        // Search only for services that match our UUID
        self.peripheral(peripheral,
                        discoverServices: nil)
    }
    @nonobjc func peripheral(_ peripheral: CBPeripheral,
                             discoverServices services: [CBUUID]?) {
        guard isDeviceConnected else {
            return
        }
        peripheral.discoverServices(services)
        print("centralManager peripheral.discoverServices(services)")
        print(CBUUID.self)
    }
    @nonobjc func peripheral(_ peripheral: CBPeripheral,
                             discoverCharacteristics characteristics: [CBUUID]?,
                             forService service: CBService) {
        guard isDeviceConnected else {
            return
        }
        peripheral.discoverCharacteristics(characteristics, for: service)
        print("peripheral.discoverCharacteristics(characteristics, for: service)")
        print(CBUUID.self)
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        if let error = error {
           print(error.localizedDescription)
        }
        isDeviceConnected = false
        connectedPeripheral = nil
        connectionLost = true
        connectionManagerDelegate?.centralManager(centralManager,
                                                   didDisconnectPeripheral: peripheral)
    }
    
    //MARK:Peripheral Delegate
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        guard error == nil else {
            cleanup()
            return
        }
        guard let services = peripheral.services else {
            return
        }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard error == nil else {
            print(error!.localizedDescription)
            cleanup()
            return
        }
        guard let characteristics = service.characteristics else {
            return
        }
        for characteristic in characteristics {
            switch characteristic.uuid {
            case BLE.characteristic.heartRateMeasurement,
                 BLE.characteristic.batteryLevel,
                 BLE.characteristic.heartData:
                peripheral.setNotifyValue(true, for: characteristic)
                print("characteristic: heartRateMeasurement or batteryLevel or heartData")
            case BLE.characteristic.firmwareRevision,
                 BLE.characteristic.manufacturerName,
                 BLE.characteristic.hardwareRevision,
                 BLE.characteristic.serialNumber:
                peripheral.readValue(for: characteristic)
                print("characteristic: firmwareRevision, manufacturerNAme, hardwareRevision")
            case BLE.characteristic.debugTX:
                TXCharacteristic = characteristic
                print("characterisitc: debugTX")
            case BLE.characteristic.debugRX:
                RXCharacteristic = characteristic
            //case BLE.characteristic.unknownCharacteristic2:
            //    peripheral.setNotifyValue(true, for: characteristic)
//            case CBUUID(string: "1008"):
//                print(characteristic.uuid)
                print("characteristic: debugRX")
            default:
//                peripheral.readValue(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)
                break
            }
        }
    }
    
    //MARK: Did update value
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard error == nil else {
            print(error?.localizedDescription ?? "Error updating value")
            return
        }
        switch characteristic.uuid {
        case BLE.characteristic.heartRateMeasurement:
            print("Update on BLE.characteristic.heartRateMeasurement")
            let heartBeat = DataMapper.convertHeartRateDataToInt(heartRateData: characteristic.value! as NSData)
            characteristicUpdateDelegate?.update(heartBeatRate: heartBeat)
        case BLE.characteristic.manufacturerName:
            print("Update on BLE.characteristic.manufacturerName")
            let datastring = String(data: characteristic.value!,
                                    encoding: String.Encoding.utf8)
            DataStorage.shared.connectedPeripheral.manufacturerName = datastring!
            characteristicUpdateDelegate?.update(deviceInfo: datastring!)
        case BLE.characteristic.hardwareRevision:
            print("Update on BLE.characteristic.hardwareRevision")
            let hardwareRevision = String(data: characteristic.value!,
                                          encoding: String.Encoding.utf8)
            DataStorage.shared.connectedPeripheral.hardwareRevision = hardwareRevision!
            characteristicUpdateDelegate?.update(hardwareRevision: hardwareRevision!)
        case BLE.characteristic.firmwareRevision:
            print("Update on BLE.characteristic.firmwareRevision")
            let firmwareVersion = String(data: characteristic.value!,
                                         encoding: String.Encoding.utf8)
            DataStorage.shared.connectedPeripheral.firmwareVersion = firmwareVersion!
            characteristicUpdateDelegate?.update(firmwareVersion: firmwareVersion!)
        case BLE.characteristic.batteryLevel:
            print("Update on BLE.characteristic.batteryLevel")
            let batteryLevel = getInt(fromData: characteristic.value!,
                                      start: 0)
            DataStorage.shared.connectedPeripheral.batteryStatus = String(batteryLevel)
            characteristicUpdateDelegate?.update(batteryLevel: batteryLevel)
        case BLE.characteristic.serialNumber:
            print("Update on BLE.characteristic.serialNumber")
            let serialNumber = String(data: characteristic.value!,
                                      encoding: String.Encoding.utf8)
            characteristicUpdateDelegate?.update(serialNumber: serialNumber!)
        //case BLE.characteristic.debugRX:
        //    break
            //print("debugRX value: ", String(data: characteristic.value!, encoding: String.Encoding.utf8))
            /*
            let stringFromData = String(data: characteristic.value!,
                                        encoding: String.Encoding.utf8)
            if stringFromData == "EOM" {
                print("DATA :" + String(data: self.data, encoding: String.Encoding.utf8)!)
                
                peripheral.setNotifyValue(false, for: characteristic)
                break
            }
            self.data.append(characteristic.value!)
            print("Received data:" + stringFromData!)
 */
            //            if (error) {
            //                NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
            //                return;
            //            }
            //
            //            NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
            //
            //            // Have we got everything we need?
            //            if ([stringFromData isEqualToString:@"EOM"]) {
            //
            //                // We have, so show the data,
            //                [self.textview setText:[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];
            //
            //                // Cancel our subscription to the characteristic
            //                [peripheral setNotifyValue:NO forCharacteristic:characteristic];
            //
            //                // and disconnect from the peripehral
            //                [self.centralManager cancelPeripheralConnection:peripheral];
            //            }
            //
            //            // Otherwise, just add the data on to what we already have
            //            [self.data appendData:characteristic.value];
            //
            //            // Log it
            //            NSLog(@"Received: %@", stringFromData);
            
        default:
            print(characteristic.uuid.uuidString)
            print(characteristic.uuid)
            break
        }
    }
    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if characteristic == self.TXCharacteristic {
            //            UIHelper.showSuccessHUDWithStatus(status: "Did write value!")
        }
    }
    
    func getInt(fromData data: Data, start: Int) -> Int {
        let intBits = data.withUnsafeBytes({(bytePointer: UnsafePointer<UInt8>) -> Int in
            bytePointer.advanced(by: start).withMemoryRebound(to: Int.self, capacity: 4) { pointer in
                return pointer.pointee
            }
        })
        return Int(littleEndian: intBits)
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        print("Error changing notification state: \(error?.localizedDescription)")
//
//        guard characteristic.uuid.isEqual(transferCharacteristicUUID) else {
//            return
//        }
//        if (characteristic.isNotifying) {
//            //DDLogInfo("Notification began on \(characteristic)")
//        } else {
//            //DDLogInfo("Notification stopped on (\(characteristic))  Disconnecting")
//            centralManager?.cancelPeripheralConnection(peripheral)
//        }
    }
    
    //MARK: Central Manager Methods
    func scan() {
        guard let centralManager = centralManager, isCentralManagerReady else {
            self.centralManager = CBCentralManager(delegate: self,
                                                   queue: nil)
            shouldScan = true
            return
        }
        centralManager.scanForPeripherals(withServices: [],
                                          options: [
                                            CBCentralManagerScanOptionAllowDuplicatesKey: true
            ])
        connectionManagerDelegate?.centralManagerStartDiscoveringDevices()
        print("Scanning started")
    }
    
    func stopScan() {
        guard let centralManager = centralManager else {
            return
        }
        centralManager.stopScan()
        print("Scanning stopped: Stop scan")
    }
    
    public func cancelConnection() {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
    }
    
    func connectionTimeoutTimerDidFire(timer: Timer) {
        let userInfo = timer.userInfo as! [String: CBPeripheral]
        guard let peripheral = userInfo["peripheral"] else {
            return
        }
        centralManager?.cancelPeripheralConnection(peripheral)
        connectionManagerDelegate?.centralManager(centralManager,
                                                   connectionToDeviceTimeout: peripheral)
        print("connectionTimeoutTimerDidFire")
    }
    
    private func cleanup() {
        guard connectedPeripheral?.state == .connected else {
            return
        }
        guard let services = connectedPeripheral?.services else {
            cancelConnection()
            return
        }
        
        for service in services {
            guard let characteristics = service.characteristics else {
                continue
            }
            
            for characteristic in characteristics {
                if characteristic.isNotifying {
                    connectedPeripheral?.setNotifyValue(false, for: characteristic)
                    return
                }
            }
        }
    }
    
}

extension ConnectionManagerDelegate {
    func centralManagerDidUpdatedState(_ state: Int) {}
    
    func centralManagerStartDiscoveringDevices() {}
    
    func centralManager(_ centralManager: CBCentralManager,
                        didDiscoverDevice peripheral: CBPeripheral) {}
    
    func centralManager(_ centralManager: CBCentralManager,
                        connectToDevice peripheral: CBPeripheral) {}
    
    func centralManager(_ centralManager: CBCentralManager,
                        lostDeviceConnection peripheral: CBPeripheral) {}
    
    func centralManager(_ centralManager: CBCentralManager,
                        connectionDidTimeout peripheral: CBPeripheral) {}
    
    func centralManager(_ centralManager: CBCentralManager,
                        didConnectPeripheral peripheral: CBPeripheral) {}
    
    func centralManager(_ centralManager: CBCentralManager,
                        connectionToDeviceFailed peripheral: CBPeripheral) {}
    
    func centralManager(_ centralManager: CBCentralManager,
                        connectionToDeviceTimeout peripheral: CBPeripheral) {}
    
    func centralManager(_ centralManager: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral) {}
}

extension PeripheralCharacteristicUpdateDelegate {
    
    func update(heartBeatRate: Int) {}
    
    func update(batteryLevel: Int) {}
    
    func update(deviceInfo: String) {}
    
    func update(firmwareVersion: String) {}
    
    func update(hardwareRevision: String) {}
    
    func update(serialNumber: String) {}
    
}
