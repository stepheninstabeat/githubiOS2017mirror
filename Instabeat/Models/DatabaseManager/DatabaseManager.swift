//
//  DatabaseManager.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 12/16/16.
//  Copyright © 2016 GL. All rights reserved.
//

import Foundation
import RealmSwift

struct DatabaseManager {
    static let shared = DatabaseManager()
    let realm = try! Realm()
    
    func save(user: User,
              failure: ((String) -> Void)?) {
        do {
            try realm.write {
                realm.add(user,
                          update: true)
            }
        }
        catch (let error) {
            failure?(error.localizedDescription)
        }
    }
    
    func save(session: Session,
              failure: ((String) -> Void)?) {
        do {
            try realm.write {
                realm.add(session,
                          update: true)
            }
        }
        catch (let error) {
            failure?(error.localizedDescription)
        }
    }
    
    func get(user userID: String,
             success: ((User) -> Void)?,
             failure: ((String) -> Void)?) {
        let predicate = NSPredicate(format: "userID == %@", userID)
        if let user = realm.objects(User.self).filter(predicate).first {
            success?(user)
        } else {
            let message = "User not found"
            print(message)
            failure?(message)
        }
    }
    
    func get(sessionForUser userID: String,
             sessionID: String,
             success: ((Session) -> Void)?,
             failure: ((String) -> Void)?) {
        let predicate = NSPredicate(format: "sessionID == %@", sessionID, userID)
        if let session = realm.objects(Session.self).filter(predicate).first {
            success?(session)
        } else {
            let message = "Session not found"
            print(message)
            failure?(message)
        }
    }
    
    func delete(user userID: String,
                failure: ((String) -> Void)?) {
        do {
            try realm.write {
                self.get(user: userID,
                         success: { (user) in
                            self.realm.delete(user)
                }, failure: { error in
                    failure?(error)
                })
            }
        }
        catch (let error) {
            failure?(error.localizedDescription)
        }
    }
    
    func delete(session: Session,
                failure: ((String) -> Void)?) {
        do {
            try realm.write {
                realm.delete(session)
            }
        }
        catch (let error) { failure?(error.localizedDescription) }
    }
    
    func deleteRealm() {
        if let realmURL = Realm.Configuration.defaultConfiguration.fileURL {
            try! realm.write {
                realm.deleteAll()
            }
            do {
                try FileManager.default.removeItem(at: realmURL)
            }
            catch (let error) { print(error.localizedDescription) }
        }
    }
}
