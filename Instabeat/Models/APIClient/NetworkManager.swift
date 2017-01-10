//
//  NetworkManager.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 10/19/16.
//  Copyright © 2016 GL. All rights reserved.
//

import Foundation
import Alamofire
import SwiftKeychainWrapper
import ObjectMapper

enum UserParameter: String {
    case email = "user[email]"
    case firstName = "user[firstName]"
    case lastName = "user[lastName]"
    case birthday = "user[birthday]"
    case password = "user[password]"
    case instabeatFirmwareVersion = "user[instabeatID.firmware]"
    case instabeatHardwareVersion = "user[instabeatID.hardware]"
    case restingHR = "user[zones.hr_resting]"
    case fatBurningMiddleZone = "user[zones.hr_fat_middle]"
    case fatBurningMaximumZone = "user[zones.hr_fat_max]"
    case fitnessMiddleZone = "user[zones.hr_fitness_middle]"
    case fitnessMaximumZone = "user[zones.hr_fitness_max]"
    case maximumPerformanceMiddleZone = "user[zones.hr_max_performance_middle]"
    case maximumPerformanceMaximumZone = "user[zones.hr_max_performance_max]"
    case paswwordConfirmation = "user[password_confirm]"
}

class NetworkManager: SessionManager {
    static let shared = NetworkManager()
    private let manager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["Accept": "application/json",
                                               "Accept-Charset": "utf-8"]
        return SessionManager(configuration: configuration)
    }()
    
    private let baseURLString = Constants.URLString.staging // TODO change to production
    
    //MARK: Login
    
    func loginUser(email: String,
                   password: String,
                   successHandler: ((String, String) -> Void)?,
                   failureHandler: ((String) -> Void)?) {
        let URL = baseURLString + "api/signin"
        let parameters =  [
            "user": [
                "email": email,
                "password": password
            ]
        ]
        self.manager.request(URL,
                             method: .post,
                             parameters: parameters,
                             encoding: URLEncoding.default,
                             headers: nil)
            .responseJSON { response in
                switch response.result {
                case .success:
                    let JSON = response.result.value as! NSDictionary
                    if let success = JSON["success"] as? Bool,
                        success == true {
                        KeychainWrapper.standard.set(email,
                                                     forKey: "InstabeatUserEmail")
                        KeychainWrapper.standard.set(password,
                                                     forKey: "InstabeatUserPassword")
                        let token = JSON["token"] as! String
                        let userID = JSON["user"] as! String
                        successHandler?(token, userID)
                    }
                    else {
                        if let error = JSON["error"] as? NSDictionary {
                            let errorMessage = error["message"] as? String ?? "Something wrong!"
                            failureHandler?(errorMessage)
                        }
                    }
                case .failure (let error):
                    failureHandler?(error.localizedDescription)
                }
        }
    }
    
    func loginUser(facebookUserID userID: String,
                   facebookUserToken userToken: String,
                   email: String,
                   firstName: String,
                   lastName: String,
                   successHandler: ((String, String, Bool) -> Void)?,
                   failureHandler: ((String) -> Void)?) {
        let parameters = [
            "facebookUser": userID,
            "facebookToken": userToken,
            UserParameter.email.rawValue: email,
            UserParameter.firstName.rawValue: firstName,
            UserParameter.lastName.rawValue: lastName,
            ] as [String: String]
        print(parameters)
        let URL = baseURLString + "api/facebookLogin"
        self.manager.request(URL,
                             method: .post,
                             parameters: parameters,
                             encoding: URLEncoding.default,
                             headers: nil)
            .responseJSON { response in
                switch response.result {
                case .success:
                    let JSON = response.result.value as! NSDictionary
                    if let success = JSON["success"] as? Bool,
                        success == true {
                        if let token = JSON["token"] as? String,
                            let userID = JSON["user"] as? String,
                            let isFirstTimeLogged = JSON["firstTime"] as? Bool {
                            successHandler?(token, userID, isFirstTimeLogged)
                        }
                    }
                    else {
                        if let error = JSON["error"] as? NSDictionary {
                            let errorMessage = error["message"] as? String ?? "Something wrong!"
                            failureHandler?(errorMessage)
                        }
                    }
                    
                case .failure (let error):
                    failureHandler?(error.localizedDescription)
                }
        }
    }
    
    func loginUser(googlePlusUserID userID: String,
                   googlePlusUserToken userToken: String,
                   email: String,
                   firstName: String,
                   lastName: String,
                   successHandler: ((_ token: String, _ userID: String, _ isFirstTimeLogged: Bool) -> Void)?,
                   failureHandler: ((_ error: String) -> Void)?) {
        let parameters = [
            "googleUser": userID,
            "googleToken": userToken,
            UserParameter.email.rawValue: email,
            UserParameter.firstName.rawValue: firstName,
            UserParameter.lastName.rawValue: lastName,
            ] as [String : Any]
        let URL = baseURLString + "api/googleLogin"
        self.manager.request(URL,
                             method: .post,
                             parameters: parameters,
                             encoding: URLEncoding.default,
                             headers: nil)
            .responseJSON { response in
                switch response.result {
                case .success:
                    let JSON = response.result.value as! NSDictionary
                    if let success = JSON["success"] as? Bool,
                        success == true {
                        if let token = JSON["token"] as? String,
                            let userID = JSON["user"] as? String,
                            let isFirstTimeLogged = JSON["firstTime"] as? Bool {
                            successHandler?(token, userID, isFirstTimeLogged)
                        }
                    }
                    else {
                        if let error = JSON["error"] as? NSDictionary {
                            let errorMessage = error["message"] as? String ?? "Something wrong!"
                            failureHandler?(errorMessage)
                        }
                    }
                    
                case .failure (let error):
                    failureHandler?(error.localizedDescription)
                }
        }
    }
    
    //MARK: Registration with email
    
    func registrationUser(email: String,
                          password: String,
                          confirmPassword: String,
                          firstName: String,
                          lastName: String,
                          successHandler: ((_ token: String, _ userID: String) -> Void)?,
                          failureHandler: ((_ error: String) -> Void)?) {
        let parameters = [
            "user":
                [
                    "email" : email,
                    "password" : password,
                    "password_confirm": confirmPassword,
                    "firstName": firstName,
                    "lastName": lastName,
            ]
        ]
        let URL = baseURLString + "api/signup"
        self.manager.request(URL,
                             method: .post,
                             parameters: parameters,
                             encoding: URLEncoding.default,
                             headers: nil)
            .responseJSON { response in
                switch response.result {
                case .success:
                    let JSON = response.result.value as! NSDictionary
                    if let success = JSON["success"] as? Bool,
                        success == true {
                        if let token = JSON["token"] as? String,
                            let userID = JSON["user"] as? String {
                            KeychainWrapper.standard.set(email,
                                                         forKey: "InstabeatUserEmail")
                            KeychainWrapper.standard.set(password,
                                                         forKey: "InstabeatUserPassword")
                            
                            successHandler?(token, userID)
                        }
                    }
                    else {
                        if let error = JSON["error"] as? NSDictionary {
                            let errorMessage = error["message"] as? String ?? "Something wrong!"
                            failureHandler?(errorMessage)
                        }
                    }
                    
                case .failure (let error):
                    failureHandler?(error.localizedDescription)
                }
        }
    }
    
    //MARK: Get User Info
    
    func getUser(userToken: String,
                 successHandler: ((_ user: User) -> Void)?,
                 failureHandler: ((_ error: String) -> Void)?) {
        let URL = baseURLString + "api/user"
        let parameters = ["token": userToken]
        self.manager.request(URL,
                             method: .get,
                             parameters: parameters,
                             encoding: URLEncoding.default,
                             headers: nil)
            .responseJSON { response in
                switch response.result {
                case .success:
                    let JSON = response.result.value as! NSDictionary
                    if let success = JSON["success"] as? Bool,
                        success == true,
                        let userData = JSON["user"] as? [String : Any] {
                        if let user = User(JSON: userData) {
                            successHandler?(user)
                        }
                    }
                    else {
                        if let error = JSON["error"] as? NSDictionary {
                            let errorMessage = error["message"] as? String ?? "Something wrong!"
                            failureHandler?(errorMessage)
                        }
                    }
                case .failure (let error):
                    failureHandler?(error.localizedDescription)
                }
        }
    }
    func getUserStatictic(userID: String,
                          userToken: String,
                          failureHandler: ((_ error: String) -> Void)?) {
        let URL = baseURLString + "api/users/\(DataStorage.shared.activeUser.userID)/stats"
        self.manager.request(URL,
                             method: .get,
                             parameters: ["token": userToken],
                             encoding: URLEncoding.default,
                             headers: nil)
            .responseJSON { response in
                switch response.result {
                case .success:
                    print(response)
                case .failure (let error):
                    failureHandler?(error.localizedDescription)
                }
        }
    }
    
    func getUserSessionsList(userID: String,
                             token: String,
                             successHandler: (([String]) -> Void)?,
                             failureHandler: ((String) -> Void)?) {
        let URL = baseURLString + "api/users/\(userID)/sessions" + "?token=\(token)"
        self.manager.request(URL,
                             method: .get,
                             parameters:nil,
                             encoding: URLEncoding.default,
                             headers: nil)
            .responseJSON { response in
                switch response.result {
                case .success:
                    let JSON = response.result.value as! NSDictionary
                    if let sessions = JSON["sessions"] as? NSArray {
                        var sessionIDs: [String] = []
                        for session in sessions {
                            if let session = session as? NSDictionary,
                                let id = session["id"] as? String {
                                sessionIDs.append(id)
                            }
                        }
                        successHandler?(sessionIDs)
                    } else {
                        if let error = JSON["error"] as? NSDictionary {
                            let errorMessage = error["message"] as? String ?? "Something wrong!"
                            failureHandler?(errorMessage)
                        }
                    }
                case .failure (let error):
                    failureHandler?(error.localizedDescription)
                }
        }
    }
    
    func downloadUserSession(userID: String,
                             token: String,
                             sessionID: String,
                             successHandler: ((_ session: Session) -> Void)?,
                             failureHandler: ((_ error: String) -> Void)?) {
        let URL = baseURLString + "api/users/\(userID)/sessions/\(sessionID)" + "?token=\(token)"
        self.manager.request(URL,
                             method: .get,
                             parameters:nil,
                             encoding: URLEncoding.default,
                             headers: nil)
            .responseJSON { response in
                switch response.result {
                case .success:
                    let JSON = response.result.value as! NSDictionary
                    if let success = JSON["success"] as? Bool,
                        success == true,
                        var sessionData = JSON["session"] as? [String : Any] {
                        sessionData["jsonData"] = DataMapper.convertStringToDictionary(sessionData["jsonData"] as! String)
                        if let session = Session(JSON: sessionData){
                            successHandler?(session)
                        } else {
                           failureHandler?("can't parse session data") 
                        }
                    } else {
                        var errorMessage = "Something wrong!"
                        if let error = JSON["error"] as? NSDictionary {
                            errorMessage = error["message"] as? String ??  "Something wrong!"
                        }
                        failureHandler?(errorMessage)
                    }
                case .failure (let error):
                    failureHandler?(error.localizedDescription)
                }
        }
    }
    
    
    //MARK: Update User Information
    
    func updateUserInformation(_ parameters: [UserParameter : Any],
                               successHandler: ((User) -> Void)?,
                               failureHandler: ((String) -> Void)?) {
        let convertedParameters = parameters.reduce( ([String : String]()), { dictionary, pair in
            var dictionary = dictionary
            dictionary[pair.key.rawValue] = String(describing: pair.value)
            return dictionary
        })
        let URL = baseURLString + "api/users/" + "\(DataStorage.shared.activeUser.userID)" + "?token=\(DataStorage.shared.activeUser.token)"
        
        self.manager.request(URL,
                             method: .post,
                             parameters: convertedParameters,
                             encoding: URLEncoding.default,
                             headers: nil)
            .responseJSON { response in
                switch response.result {
                case .success:
                    let JSON = response.result.value as! NSDictionary
                    if let success = JSON["success"] as? Bool,
                        success == true,
                        let userData = JSON["user"] as? [String : Any] {
                        if let user = User(JSON: userData) {
                            successHandler?(user)
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateUserInformation"), object: nil)
                        }
                    } else {
                        if let error = JSON["error"] as? NSDictionary {
                            let errorMessage = error["message"] as? String ?? "Something wrong!"
                            failureHandler?(errorMessage)
                        }
                    }
                case .failure (let error):
                    failureHandler?(error.localizedDescription)
                }
        }
    }
    
    func linkIBDevice(hardwareID: String,
                      firmwareID: String,
                      successHandler: ((User) -> Void)?,
                      failureHandler: ((String) -> Void)?) {
        let URL = baseURLString + "api/link/" + "\(DataStorage.shared.activeUser.userID)" + "?token=\(DataStorage.shared.activeUser.token)"
        
        let parameters = ["hardwareID": hardwareID,
                          "firmwareID": firmwareID]
        self.manager.request(URL,
                             method: .post,
                             parameters: parameters,
                             encoding: URLEncoding.default,
                             headers: nil)
            .responseJSON { response in
                switch response.result {
                case .success:
                    let JSON = response.result.value as! NSDictionary
                    if let success = JSON["success"] as? Bool,
                        success == true,
                        let userData = JSON["user"] as? [String : Any] {
                        if let user = User(JSON: userData) {
                            successHandler?(user)
                            NotificationCenter.default.post(name:  NSNotification.Name(rawValue: "updateUserInformation"), object: nil)
                        }
                    } else {
                        if let error = JSON["error"] as? NSDictionary {
                            let errorMessage = error["message"] as? String ?? "Something wrong!"
                            failureHandler?(errorMessage)
                        }
                    }
                    
                case .failure (let error):
                    failureHandler?(error.localizedDescription)
                }
        }
    }
    
    func unlinkIBDevice(hardwareID: String,
                        successHandler: ((User) -> Void)?,
                        failureHandler: ((String) -> Void)?) {
        let URL = baseURLString + "api/unlink/" + "\(DataStorage.shared.activeUser.userID)" + "?token=\(DataStorage.shared.activeUser.token)"
        
        let parameters = ["hardwareID": hardwareID]
        self.manager.request(URL,
                             method: .post,
                             parameters: parameters,
                             encoding: URLEncoding.default,
                             headers: nil)
            .responseJSON { response in
                switch response.result {
                case .success:
                    let JSON = response.result.value as! NSDictionary
                    if let success = JSON["success"] as? Bool,
                        success == true,
                        let userData = JSON["user"] as? [String : Any] {
                        if let user = User(JSON: userData) {
                            successHandler?(user)
                            NotificationCenter.default.post(name:  NSNotification.Name(rawValue: "updateUserInformation"), object: nil)
                        }
                    } else {
                        if let error = JSON["error"] as? NSDictionary {
                            let errorMessage = error["message"] as? String ?? "Something wrong!"
                            failureHandler?(errorMessage)
                        }
                    }
                case .failure (let error):
                    failureHandler?(error.localizedDescription)
                }
        }
    }
    
    //func  updateUser(firstName: String) {
    //
    //}
    
    func uploadUserSession(session: String,
                           successHandler: ((String) -> Void)?,
                           failureHandler: ((String) -> Void)?)  {
        let URL = baseURLString + "api/users/\(DataStorage.shared.activeUser.userID)/sessions" + "?token=\(DataStorage.shared.activeUser.token)"
        self.manager.request(URL,
                             method: .post,
                             parameters: ["session": session],
                             encoding: URLEncoding.default,
                             headers: nil)
            .responseJSON { response in
                switch response.result {
                case .success:
                    let JSON = response.result.value as! NSDictionary
                    if let success = JSON["success"] as? Bool,
                        success == true {
                        successHandler?(JSON["session"] as! String)
                    }
                    else {
                        if let error = JSON["error"] as? NSDictionary {
                            let errorMessage = error["message"] as? String ?? "Something wrong!"
                            failureHandler?(errorMessage)
                        }
                    }
                case .failure (let error):
                    failureHandler?(error.localizedDescription)
                }
        }
    }
    
    func updateUserSession(sessionID: String,
                           date: Date,
                           successHandler: ((String) -> Void)?,
                           failureHandler: ((String) -> Void)?)  {
        let URL = baseURLString + "api/users/\(DataStorage.shared.activeUser.userID)/sessions/\(sessionID)" + "?token=\(DataStorage.shared.activeUser.token)"
        self.manager.request(URL,
                             method: .post,
                             parameters: ["session[date]": date.iso8601],
                             encoding: URLEncoding.default,
                             headers: nil)
            .responseJSON { response in
                switch response.result {
                case .success:
                    let JSON = response.result.value as! NSDictionary
                    let success = JSON["success"] as! Bool
                    if success == true {
                        successHandler?("")
                    } else {
                        if let error = JSON["error"] as? NSDictionary {
                            let errorMessage = error["message"] as? String ?? "Something wrong!"
                            failureHandler?(errorMessage)
                        }
                    }
                    
                case .failure (let error):
                    failureHandler?(error.localizedDescription)
                }
        }
    }
}
