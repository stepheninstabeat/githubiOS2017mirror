//
//  DataCoordinator.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 12/16/16.
//  Copyright © 2016 GL. All rights reserved.
//

import Foundation

class DataCoordinator {
    
    class func downloadUserSessions(userID: String,
                                    token: String,
                                    sessionsIDs: [String],
                                    completted: (() -> Void)?) {
        UIHelper.showHUDLoading()
        let group = DispatchGroup()
        var parsedSessions: [Session] = []
        for id in sessionsIDs {
            group.enter()
            DatabaseManager.shared.get(sessionForUser: userID,
                                       sessionID: id,
                                       success: { (session) in
                                        parsedSessions.append(session)
                                        group.leave()
            }, failure: { (_) in
                NetworkManager.shared.downloadUserSession(userID: userID,
                                                          token: token,
                                                          sessionID: id,
                                                          successHandler: { (session) in
                                                            parsedSessions.append(session)
                                                            group.leave()
                }, failureHandler: { (error) in
                    print(error)
                    group.leave()
                })
            })
        }
        group.notify(queue: .main) {
            print("begin write")
            DatabaseManager.shared.realm.beginWrite()
            parsedSessions.forEach({ $0.owner = DataStorage.shared.activeUser })
            DataStorage.shared.activeUser.sessions.append(objectsIn: parsedSessions.sorted { $0.date < $1.date })
            do {
                try DatabaseManager.shared.realm.commitWrite()
                DatabaseManager.shared.save(user: DataStorage.shared.activeUser,
                                            failure: nil)
            }
            catch { }
            
            UIHelper.dismissHUD()
            completted?()
        }
    }
}
