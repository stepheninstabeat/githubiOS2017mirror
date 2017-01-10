//
//  Lap.swift
//  Instabeat
//
//  Created by Dmytro on 5/19/16.
//  Copyright © 2016 GL. All rights reserved.
//

import Foundation
import ObjectMapper
import RealmSwift

class Lap: Object, Mappable {
    dynamic var lapID: Int = 0
    dynamic var startTime: Double {
        get {
            return startTimeMiniSecons/10
        }
    }
    dynamic var startTimeMiniSecons: Double = 0
    dynamic var endTime: Double {
        get {
            return endTimeMiniSecons/10
        }
    }
    dynamic var endTimeMiniSecons: Double = 0
    dynamic var duration: Double {
        get {
            guard startTime > 0, endTime > 0, startTime < endTime else { return 0 }
            return endTime - startTime
        }
    }
    dynamic var speed: Double = 0
    dynamic var interval: Double = 0
    dynamic var pace: Double = 0
    dynamic var averageHR: Int {
        get {
            guard !BPMS.isEmpty else { return 0 }
            return Int(round(BPMS.reduce(0.0) { $0 + $1.value } / Double(BPMS.count)))
        }
    }
    dynamic var style: String = ""
    dynamic var turn: String = ""
    var BPMS: [HeartRate] {
        get {
            guard !(owner?.bpms.isEmpty)! else { return []}
            return owner!.bpms.filter{ (self.startTime..<self.endTime).contains($0.time) }
        }
    }
    dynamic var strokes: NSNumber = 0
    dynamic var owner: Session?
    
    // Mappable
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        lapID                   <- map["lap_id"]
        startTimeMiniSecons     <- map["start_time"]
        endTimeMiniSecons       <- map["end_time"]
        speed                   <- map["speed"]
        interval                <- map["interval"]
        pace                    <- map["pace"]
        style                   <- map["style"]
        turn                    <- map["turn"]
        strokes                 <- map["strokes"]
    }
}
