//
//  SearchDeviceTableViewController.swift
//  Instabeat
//
//  Created by Dmytro on 5/4/16.
//  Copyright © 2016 GL. All rights reserved.
//

//enum infoMessage: String {
//    case selectDevice = "PLEASE SELECT YOUR DEVICE"
//    case centralManagerOff = "YOUR BLUETOOTH IS OFF!"
//    case noDevicesFound = "NO DEVICES FOUND!"
//}
import UIKit
import CoreBluetooth

class SearchDeviceTableViewController: UITableViewController {    
    @IBOutlet var headerView: UIView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var foundDevicesArray:[CBPeripheral] = []
    var isPresent = false
    var infoLabelMessage = "" {
        didSet {
            infoLabel.text = infoLabelMessage
            isProblemWithSearch = true
            activityIndicator.isHidden = true
            switch infoLabelMessage {
            case "YOUR BLUETOOTH IS OFF!":
                problemMessage = "Please turn on your Bluetooth to allow the app to connect to your Instabeat"
                foundDevicesArray.removeAll()
                activityIndicator.stopAnimating()
            case "NO DEVICES FOUND!":
                problemMessage = "Please make sure your Instabeat is turned on and close to your phone to connect it to the app"
            case "PLEASE SELECT YOUR DEVICE":
                foundDevicesArray.removeAll()
                activityIndicator.startAnimating()
                problemMessage = ""
                activityIndicator.isHidden = false
                isProblemWithSearch = false
            default:
                break
            }
            tableView.reloadData()
        }
    }
    private var isProblemWithSearch = false
    private var problemMessage = ""
    private var timers: [Timer] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        infoLabelMessage = "PLEASE SELECT YOUR DEVICE" 
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIHelper.restrictRotation(restrict: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _ = timers.map({ $0.invalidate() })
    }
    
    // MARK:Table view data source
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        if isProblemWithSearch {
            if infoLabelMessage == "NO DEVICES FOUND!" {
                return 2
            }
            return 1
        }
        return foundDevicesArray.count
    }
    
    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isProblemWithSearch {
            if infoLabelMessage == "NO DEVICES FOUND!" && indexPath.row == 1 {
                return 50
            }
            return 100
        }
        return 35
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.searchDeviceCellIdentifier)
        if cell == nil {
            cell = UITableViewCell.init()
        }
        cell!.textLabel!.numberOfLines = 0
        cell!.textLabel!.lineBreakMode = .byWordWrapping
        if isProblemWithSearch {
            if infoLabelMessage == "NO DEVICES FOUND!" && indexPath.row == 1 {
                cell!.textLabel!.text = "RETRY SEARCH"
            } else {
                cell!.textLabel!.text = problemMessage
            }
            return cell!
        }
        let peripheral = foundDevicesArray[indexPath.row]
        cell!.textLabel!.text = peripheral.name
        return cell!
    }

    // MARK:Table view delegate
    override func tableView(_ tableView: UITableView,
                            heightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
    }
    
    override func tableView(_ tableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {
        return headerView
    }
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        if isProblemWithSearch {
            if infoLabelMessage == "NO DEVICES FOUND!" && indexPath.row == 1 {
                infoLabelMessage = "PLEASE SELECT YOUR DEVICE"
                CentralBuetoothManager.shared.scan()
                foundDevicesArray.removeAll()
                tableView.reloadData()
            }
            return
        }
        CentralBuetoothManager.shared.stopScan()
        let peripheral = foundDevicesArray[indexPath.row]
        CentralBuetoothManager.shared.centralManager(connectPeripheral: peripheral,
                                                     timeOut: 15.0)
    }
    //MARK: Devices management
    func found(device: CBPeripheral) {
        if let index = foundDevicesArray.index(of: device) {
            timers[index].invalidate()
            timers[index] = Timer.scheduledTimer(timeInterval: 10.0,
                                                 target: self,
                                                 selector: #selector(self.update(timer:)),
                                                 userInfo: ["device" : device],
                                                 repeats: true)
            return
        }
        foundDevicesArray.append(device)
        addTimerFor(device: device)
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(item: foundDevicesArray.count - 1,
                                        section: 0)],
                         with: .right)
        tableView.endUpdates()
    }
    
    ///Timer for remove device if this not available more
    
    private func addTimerFor(device: CBPeripheral) {
        let timer = Timer.scheduledTimer(timeInterval: 30.0,
                                         target: self,
                                         selector: #selector(self.update(timer:)),
                                         userInfo: ["device" : device],
                                         repeats: true)
        
        timers.append(timer)
    }
    
    func update(timer: Timer) {
        let dictionary = timer.userInfo as! Dictionary<String, Any>
        let device: CBPeripheral = dictionary["device"] as! CBPeripheral
        let index = foundDevicesArray.index(of: device)!
        timers[index].invalidate()
        timers.remove(at: index)
        foundDevicesArray.remove(at: index)
        tableView.beginUpdates()
        tableView.deleteRows(at: [IndexPath(item:index,
                                            section: 0)],
                             with: .left)
        tableView.endUpdates()
    }
}
