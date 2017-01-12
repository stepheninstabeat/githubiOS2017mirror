//
//  DataMapper.swift
//  Instabeat
//
//  Created by Dmytro on 5/11/16.
//  Copyright © 2016 GL. All rights reserved.
//

import Foundation
//import SwimLibSwift
import ObjectMapper

class DataMapper: NSObject {
    class func convertHeartRateDataToInt(heartRateData data: NSData) -> Int {
//        var buffer = [UInt8](repeating: 0x00, count: data.length)
//        data.getBytes(&buffer, length: buffer.count)
//        var bpm:UInt16!
//        if (buffer.count >= 2){
//            if (buffer[0] & 0x01 == 0){
//                bpm = UInt16(buffer[1]);
//            }else {
//                bpm = UInt16(buffer[1]) << 8
//                bpm =  bpm! | UInt16(buffer[2])
//            }
//        }
        var buf : UInt16! = 0
        data.getBytes(&buf, range: NSRange(location: 0, length: 2))

        return Int(buf)
    }
    class func convertStringToDictionary(_ text: String) -> [String: Any]? {
        if let data = text.data(using: String.Encoding.utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            }
            catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
}

class DataParser: NSObject {
    /**
     Parse data from session file.
     
     - parameter sessionFileName: name of session file.
     
     - returns: Session file or error string.
     */
    class func parseDataFromSessionFile(sessionFileName fileName: String) ->(session :Session?, errorMessage: String?) {
        let file = "\(fileName).txt" //this is the file. we will write to and read from it
        if let dir = FileManager.default.urls(for: .documentDirectory,
                                              in: .userDomainMask).first {

            let path = dir.appendingPathComponent(file)
            do {
                let data = try String(contentsOf: path, encoding: String.Encoding.utf8)
                var ident: NSValue?;
                //SwimLibrary.swimLibOpen(&ident)
                //SwimLibrary.swimLibExec(ident, data: data, poolLength: 25)
                //guard let jsonObject = SwimLibrary.swimLibResultJSON(ident),
                //    let dictionary = DataMapper.convertStringToDictionary(jsonObject),
                //    let session = Mapper<Session>().map(JSON: dictionary) else {
                //    return (nil, "Can't parse session data")
                //}
                //SwimLibrary.swimLibClose(ident)
//                return (session, nil)
                return (nil, nil)
            }
            catch {
                return (nil, "Can't parse session data")
            }
        }
        return (nil, "Can't parse session data")
    }
    
}

