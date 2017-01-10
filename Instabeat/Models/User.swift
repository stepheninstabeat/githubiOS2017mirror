//
//  User.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 11/11/16.
//  Copyright © 2016 GL. All rights reserved.
//

import Foundation
import ObjectMapper
import RealmSwift

class User: Object, Mappable {
    dynamic var email: String = ""
    dynamic var birthday: Date?
    dynamic var restingHR: Int = 0
    dynamic var fatBurningMiddleZone: Int = 0
    dynamic var fatBurningMaximumZone: Int = 0
    dynamic var fitnessMiddleZone: Int = 0
    dynamic var fitnessMaximumZone: Int = 0
    dynamic var maximumPerformanceMiddleZone: Int = 0
    dynamic var maximumPerformanceMaximumZone: Int = 0
    dynamic var firstName: String = ""
    dynamic var lastName: String = ""
    dynamic var token: String = ""
    dynamic var userID: String = ""
    dynamic var instabeatFirmwareVersion: String = ""
    dynamic var instabeatHardwareVersion: String = ""
    
    var sessions = List<Session>()
    
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter
    }()
    
    var age: Int {
        guard let birthdayDate = birthday else {
            return 0
        }
        return Date().years(from: birthdayDate)
    }
    
    override static func primaryKey() -> String? {
        return "userID"
    }

    // Mappable
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        birthday                        <- (map["birthday"], TransformOf<Date, String>(fromJSON: { self.dateFormatter.date(from: $0!) }, toJSON: { $0.map { self.dateFormatter.string(from: $0)} }))
        email                           <- map["email"]
        instabeatHardwareVersion        <- map["instabeatID.hardware"]
        instabeatFirmwareVersion        <- map["instabeatID.firmware"]
        restingHR                       <- map["zones.hr_resting"]
        fatBurningMiddleZone            <- map["zones.hr_fat_middle"]
        fatBurningMaximumZone           <- map["zones.hr_fat_max"]
        fitnessMiddleZone               <- map["zones.hr_fitness_middle"]
        fitnessMaximumZone              <- map["zones.hr_fitness_max"]
        maximumPerformanceMiddleZone    <- map["zones.hr_max_performance_middle"]
        maximumPerformanceMaximumZone   <- map["zones.hr_max_performance_max"]
        firstName                       <- map["firstName"]
        lastName                        <- map["lastName"]
        token                           <- map["token"]
        userID                          <- map["_id"]
    }

}
