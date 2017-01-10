//
//  HeartRate.swift
//  Instabeat
//
//  Created by Dmytro on 5/25/16.
//  Copyright © 2016 GL. All rights reserved.
//

import Foundation
import ObjectMapper
import RealmSwift

class HeartRate: Object, Mappable {
    
    var time: Double {
        get {
            return timeMicroSec/1000
        }
    }
    dynamic var timeMicroSec: Double = 0
    dynamic var value: Double = 0
    dynamic var owner: Session?
    
    // Mappable
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        timeMicroSec    <- map["time"]
        value           <- map["value"]
    }
    
}
