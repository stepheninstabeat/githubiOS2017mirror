//
//  Utility.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 7/13/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit
import RealmSwift

class Utility: NSObject {
    ///Convert seconds to time string
    class func secondsToTimeString(_ seconds: Double) -> String {
        let (hours, minutes, seconds) = secondsToHoursMinutesSeconds(seconds: seconds)
        var timeString = ""
        if hours > 0{
            timeString += String(format: "%02d:", hours)
        }
        timeString += String(format: "%02d:%02d", minutes, seconds)
        return timeString
    }
    ///Convert seconds to hours, minutes adn seonds
    private class func secondsToHoursMinutesSeconds(seconds : Double) -> (Int, Int, Int) {
        let (hr, minf) = modf (seconds / 3600)
        let (min, secf) = modf (60 * minf)
        return (Int(hr), Int(min), Int(60 * secf))
    }
    /// Get color and Heart Rate zone for heart rate value
    class func colorForHeartRateZone(heartRate: Int,
                                     highlightedZone: HeartRateZone) -> (zone: HeartRateZone, color: UIColor) {
        var color: UIColor
        var zone: HeartRateZone
        switch heartRate {
        case 1..<DataStorage.shared.activeUser.fatBurningMaximumZone:
            color = Constants.primaryColors.zoneBlueColor
            
            zone = .fat
        case DataStorage.shared.activeUser.fatBurningMaximumZone..<DataStorage.shared.activeUser.fitnessMaximumZone:
            color = Constants.primaryColors.zoneYellowColor
            zone = .fit
        case DataStorage.shared.activeUser.fitnessMaximumZone..<300:
            color = Constants.primaryColors.zoneRedColor
            zone = .max
        default:
            color = Constants.primaryColors.whiteColor
            zone = .none
        }
        if highlightedZone == zone || highlightedZone == .none {
            return (zone, color)
        }
        return (zone, Constants.primaryColors.mediumGreyColor)
    }
    
    /// Invoke something after delay
    class func delay(delay: Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            closure()
        }
    }
    
    class func getDataForBarChartView(bpms: List<HeartRate>,
                                      totalDistance: Double,
                                      duration: Double,
                                      completionHandler:@escaping (_ values: [Double], _ colors: [UIColor]) -> Void){
        //DispatchQueue.global(qos: .default).async {
            // do some asynchronous work
            var values: [Double] = []
            var colors: [UIColor] = []
            if bpms.isEmpty {
                values.append(totalDistance)
                colors.append(Utility.colorForHeartRateZone(heartRate: 0,
                                                            highlightedZone: .none).color)
                //DispatchQueue.main.async {
                    completionHandler(values, colors)
               // }
            }
            else {
                var currentHeartRateZone: HeartRateZone = .none
                var value: Double = 0
                
                for heartRate in bpms {
                    let actualHeartRateZone = Utility.colorForHeartRateZone(heartRate: Int(heartRate.value),
                                                                            highlightedZone: .none)
                    if actualHeartRateZone.zone != currentHeartRateZone {
                        colors.append(actualHeartRateZone.color)
                        let currentTime = Double(heartRate.time)
                        let percetTime = (currentTime / duration)
                        let position = percetTime * Double(totalDistance)
                        value = position
                        let previousValue: Double = values.reduce(0, +)
                        values.append(value - previousValue)
                        currentHeartRateZone = actualHeartRateZone.zone
                    }
                }
                let previousValue: Double = values.reduce(0, +)
                values.append(totalDistance - previousValue)
                colors.append(colors.last!)
            }
            //DispatchQueue.main.async {
                completionHandler(values, colors)
          //  }
            
        //}
    }
    class func getPercentValue(zone: HeartRateZone,
                               bpms: List<HeartRate>) -> Int {
        let zoneValue: (Int, Int)
        switch zone {
        case .fat:
            zoneValue = (1, DataStorage.shared.activeUser.fatBurningMaximumZone)
        case .fit:
            zoneValue = (DataStorage.shared.activeUser.fatBurningMaximumZone, DataStorage.shared.activeUser.fitnessMaximumZone)
        case .max:
            zoneValue = (DataStorage.shared.activeUser.fitnessMaximumZone, 300)//cos of unreal HR for human
        default:
            return 0
        }
        let zoneBPM = bpms.filter({ (zoneValue.0..<zoneValue.1).contains(Int($0.value)) })
        return Int(Float(zoneBPM.count)/Float(bpms.count) * 100)
    }
    ///Check if email is valid
    class func isValid(email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
    
    class func validateUserHRZones(user: User) -> Bool {
        if user.fatBurningMaximumZone > user.fitnessMaximumZone || user.fitnessMaximumZone > 300 {
            return false
        }
        return true
    }
    
    class func colorWithHex(hex: String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.characters.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    
    class func calculate(fatBurningMiddleZone restingHR: Int) -> Int {
        //        ((((206,9 - (0,67 x AGE))-RHR) x FBZM) + RHR) x (1 - AD)
        let age = Float(DataStorage.shared.activeUser.age)
        let RHR = Float(restingHR)
        let FBZM: Float = 0.58
        let AD: Float = 0.13
        let fatFitLimitHR = ((((206.9 - (0.67 * age)) - RHR) * FBZM) + RHR) * (1 - AD)
        return Int(round(fatFitLimitHR))
    }
    
    class func calculate(fatBurningMaximumZone restingHR: Int) -> Int {
        //        ((((206,9 - (0,67 x AGE))-RHR) x FBZH) + RHR) x (1 - AD)
        let age = Float(DataStorage.shared.activeUser.age)
        let RHR = Float(restingHR)
        let FBZH: Float = 0.64
        let AD: Float = 0.13
        let fatFitLimitHR = ((((206.9 - (0.67 * age)) - RHR) * FBZH) + RHR) * (1 - AD)
        return Int(round(fatFitLimitHR))
    }
    
    class func calculate(fitnessMiddleZone restingHR: Int) -> Int {
        //        ((((206,9 - (0,67 x AGE))-RHR) x FZM) + RHR) x (1 - AD)
        let age = Float(DataStorage.shared.activeUser.age)
        let RHR = Float(restingHR)
        let FZM: Float = 0.76
        let AD: Float = 0.13
        let fatFitLimitHR = ((((206.9 - (0.67 * age)) - RHR) * FZM) + RHR) * (1 - AD)
        return Int(round(fatFitLimitHR))
    }
    
    class func calculate(fitnessMaximumZone restingHR: Int) -> Int {
        //        ((((206,9 - (0,67 x AGE))-RHR) x FZH) + RHR) x (1 - AD)
        let age = Float(DataStorage.shared.activeUser.age)
        let RHR = Float(restingHR)
        let FZH: Float = 0.82
        let AD: Float = 0.13
        let fatFitLimitHR = ((((206.9 - (0.67 * age)) - RHR) * FZH) + RHR) * (1 - AD)
        return Int(round(fatFitLimitHR))
    }
    
    class func calculate(maximumPerformanceMiddleZone restingHR: Int) -> Int {
        //        ((((206,9 - (0,67 x AGE))-RHR) x MPM) + RHR) x (1 - AD)
        let age =  Float(DataStorage.shared.activeUser.age)
        let RHR = Float(restingHR)
        let MPM: Float = 0.925
        let AD: Float = 0.13
        let fatFitLimitHR = ((((206.9 - (0.67 * age)) - RHR) * MPM) + RHR) * (1 - AD)
        return Int(round(fatFitLimitHR))
    }
    
    class func calculate(maximumPerformanceMaximumZone restingHR: Int) -> Int {
        //        ((((206,9 - (0,67 x AGE))-RHR) x MPZM) + RHR) x (1 - AD)
        let age =  Float(DataStorage.shared.activeUser.age)
        let RHR = Float(restingHR)
        let MPZM: Float = 0.94
        let AD: Float = 0.13
        let fatFitLimitHR = ((((206.9 - (0.67 * age)) - RHR) * MPZM) + RHR) * (1 - AD)
        return Int(round(fatFitLimitHR))
    }
}

class RealmString: Object {
    dynamic var stringValue = ""
}

extension Date {
    /// Returns the amount of years from another date
    func years(from date: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
    }
    /// Returns the amount of months from another date
    func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
    /// Returns the amount of weeks from another date
    func weeks(from date: Date) -> Int {
        return Calendar.current.dateComponents([.weekOfYear], from: date, to: self).weekOfYear ?? 0
    }
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    /// Returns the amount of hours from another date
    func hours(from date: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
    }
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    /// Returns the a custom time interval description from another date
    func offset(from date: Date) -> String {
        if years(from: date)   > 0 { return "\(years(from: date))y"   }
        if months(from: date)  > 0 { return "\(months(from: date))M"  }
        if weeks(from: date)   > 0 { return "\(weeks(from: date))w"   }
        if days(from: date)    > 0 { return "\(days(from: date))d"    }
        if hours(from: date)   > 0 { return "\(hours(from: date))h"   }
        if minutes(from: date) > 0 { return "\(minutes(from: date))m" }
        if seconds(from: date) > 0 { return "\(seconds(from: date))s" }
        return ""
    }
}
public extension UIImage {
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

extension Date {
    struct Formatter {
        static let iso8601: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            return formatter
        }()
    }
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
}


extension String {
    var dateFromISO8601: Date? {
        return Date.Formatter.iso8601.date(from: self)
    }
}

