//
// Session.swift
// Instabeat
//
// Created by Dmytro on 5/19/16.
// Copyright © 2016 GL. All rights reserved.
//

import Foundation
import ObjectMapper
import RealmSwift
import ObjectMapper_Realm

class Session: Object, Mappable {
    var laps = List<Lap>() {
        didSet {
            self.laps.forEach{ $0.owner = self }
        }
    }
    var bpms = List<HeartRate>() {
        didSet {
            self.bpms.forEach{ $0.owner = self }
        }
    }
    
    dynamic var sessionID: String = ""
    dynamic var duration: Double {
        get {
            return durationMicrosec/1000
        }
    }
    dynamic var durationMicrosec: Double = 0
    dynamic var totalSwimLength: Float = 0
    dynamic var splitTimes: Int = 0
    dynamic var averagePace: Float = 0
    dynamic var totalSwimTime: Float = 0
    dynamic var totalRestTime: Float = 0
    dynamic var averageSpeed: Float = 0
    dynamic var intervalsCount: Int = 0
    dynamic var owner: User?
    
    var averageHeartRate: Int {
        get {
            guard !bpms.isEmpty else { return 0 }
            return Int(round(bpms.reduce(0.0) { $0 + $1.value } / Double(bpms.count)))
        }
    }
    var maxHeartRate: HeartRate? {
        get {
            guard !bpms.isEmpty else {
                return nil
            }
            return bpms.max( by: { $0.value < $1.value})
        }
    }
    dynamic var poolLenght: Int = 25 //m

    dynamic var date: Date!

    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter
    }()
    override static func primaryKey() -> String? {
        return "sessionID"
    }
    // Mappable
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        laps                <- (map["jsonData.laps"], ListTransform<Lap>())
        bpms                <- (map["jsonData.bpm"], ListTransform<HeartRate>())
        sessionID           <- map["_id"]
        durationMicrosec    <- map["jsonData.session_info.duration"]
        totalSwimLength     <- map["jsonData.session_info.totalSwimLength"]
        splitTimes          <- map["jsonData.session_info.splitTimes"]
        averagePace         <- map["jsonData.session_info.averagePace"]
        totalSwimTime       <- map["jsonData.session_info.totalSwimTime"]
        totalRestTime       <- map["jsonData.session_info.totalRestTime"]
        averageSpeed        <- map["jsonData.session_info.averageSpeed"]
        intervalsCount      <- map["jsonData.session_info.intervalsCount"]
        poolLenght          <- map["jsonData.session_info.poolLenght"]
        date                <- (map["date"], TransformOf<Date, String>(fromJSON: { self.dateFormatter.date(from: $0!) }, toJSON: { $0.map { self.dateFormatter.string(from: $0)} }))
    }
}
