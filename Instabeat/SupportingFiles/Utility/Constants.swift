//
//  Constants.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 7/7/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit
import CoreBluetooth

enum PeripheralDeviceConnectionState {
    case Connected
    case SearchingForDevice
    case ConnectedWaitingForData
    case Disconnected
    case BluetoothUnavailable
}

struct Constants {
    struct primaryColors {
        static let darkGrayColor            = Utility.colorWithHex(hex:"#36363B")
        static let mediumGreyColor          = Utility.colorWithHex(hex:"#3F3F45")
        static let whiteColor               = Utility.colorWithHex(hex:"#ffffff")
        static let zoneBlueColor            = Utility.colorWithHex(hex:"#6FC3FC")
        static let zoneYellowColor          = Utility.colorWithHex(hex:"#F2D64B")
        static let zoneRedColor             = Utility.colorWithHex(hex:"#FF3867")
        static let yellowColor              = Utility.colorWithHex(hex:"#F2D64B")
    }
    
    struct secondaryColors {
        static let lightGrey1Color          = Utility.colorWithHex(hex:"#646464")
        static let lightGrey2Color          = Utility.colorWithHex(hex:"#88888F")
        static let lightGrey3Color          = Utility.colorWithHex(hex:"#8A8A8A")
        static let lightGrey4Color          = Utility.colorWithHex(hex:"#D0D0D0")
        static let lightGrey5Color          = Utility.colorWithHex(hex:"#E7E7EB")
        static let facebookBlueColor        = Utility.colorWithHex(hex:"#4D88FF")
        static let whiteColor               = Utility.colorWithHex(hex:"#FFFFFF")
    }
    
    struct fonts {
        static let blenderBook              = UIFont(name: "BlenderPro-Book",   size: 16.0)
        static let blenderBold              = UIFont(name: "BlenderPro-Bold",   size: 16.0)
        static let blenderMedium            = UIFont(name: "BlenderPro-Medium", size: 16.0)
        static let blenderBoldNavigationBar = UIFont(name: "BlenderPro-Bold",   size: 20.0)
        static let blenderBoldTabBar        = UIFont(name: "BlenderPro-Bold",   size: 12.0)
    }
    
    struct URLString {
        static let production   = "http://www.instabe.at/"
        static let staging      = "http://staging-keystone-instabeat-1884199394.us-west-2.elb.amazonaws.com/"
    }
}

struct CellIdentifier {
    static let barChartCellIdentifier               = "barChartCellIdentifier"
    static let searchDeviceCellIdentifier           = "searchDeviceCellIdentifier"
    static let sessionDataTableViewCellIdentifier   = "sessionDataTableViewCellIdentifier"
    static let sessionsTableViewCellIdentifier      = "sessionsTableViewCellIdentifier"
}

enum HeartRateZone {
    case none
    case fat
    case fit
    case max
}

enum Filter {
    case all
    case zoneMax
    case zoneFit
    case zoneFat
    case strokeFreestyle
    case strokeBackstroke
    case strokeBreaststroke
    case strokeButterfly
    case rest
}

struct BLE {
    
    struct service {
        static let hearRate                 = CBUUID(string: "180D")    //Heart Rate
        static let deviceInformation        = CBUUID(string: "180A")    //Device Information
        static let battery                  = CBUUID(string: "180F")    //Battery Service
        static let controlStatusService     = CBUUID(string: "58414000-B42C-47D5-8CC1-374E8B9DE5B4") //Control Status Servie
    }
    
    struct characteristic {
        static let manufacturerName         = CBUUID(string: "2A29")    //Manufacturer Name String
        static let hardwareRevision         = CBUUID(string: "2A27")    //Hardware Revision String
        static let firmwareRevision         = CBUUID(string: "2A26")    //Firmware Revision String
        static let heartRateMeasurement     = CBUUID(string: "2A37")    //heart Rate Measurement String
        static let batteryLevel             = CBUUID(string: "2A19")    //Battery Level
        static let serialNumber             = CBUUID(string: "2A25")    //serialNumber
        
        static let heartData                = CBUUID(string: "58415104-B42C-47D5-8CC1-374E8B9DE5B4")    //Heart Data
        
        static let debugRX                  = CBUUID(string: "58415A41-B42C-47D5-8CC1-374E8B9DE5B4")    //UART like set of ASCII characters input into the device.
        static let debugTX                  = CBUUID(string: "58415A40-B42C-47D5-8CC1-374E8B9DE5B4")    //UART like set of ASCII characters output from the device. Must end in a 0x00 byte.
        
        static let control                  = CBUUID(string: "58415004-B42C-47D5-8CC1-374E8B9DE5B4")    //Control characteristic
        static let status                   = CBUUID(string: "58415000-B42C-47D5-8CC1-374E8B9DE5B4")    //Status characteristic
    }
}
