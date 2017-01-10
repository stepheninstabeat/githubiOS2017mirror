//
//  AppDelegate.swift
//  Instabeat
//
//  Created by Dmytro on 4/25/16.
//  Copyright © 2016 GL. All rights reserved.
//  
//  This is a duplicate of the iOS repo with SwimLib removed.
//

import UIKit
import Fabric
import Crashlytics
import SwiftKeychainWrapper
import FacebookCore
import FacebookLogin
import GoogleSignIn
import GGLSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    /// restrictRotation bool variable responcible to restrict device rotation
    var restrictRotation = true
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Thread.sleep(forTimeInterval: 2.0)//badcode to show launchscreen longer that app need it
        
        if let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView {
            statusBar.backgroundColor = Constants.primaryColors.mediumGreyColor
        }
        
        let sessions = [
            "session 1",
            "session 2",
            "session 3",
            "session 4",
            "session 5",
            "session 8",
            ]
        
        let result = UserDefaults.standard.value(forKey: "SessionFilesSavedInDocumentsDirectory") as? Bool
        if result != true {
            
            for session in sessions {
                let file = "\(session).txt" //this is the file. we will write to and read from it
                let dataPath = Bundle.main.path(forResource: session,
                                                ofType: "txt")
                do {
                    let data = try String(contentsOfFile: dataPath!)
                    if let dir = FileManager.default.urls(for: .documentDirectory,
                                                          in: .userDomainMask).first {
                        
                        let path = dir.appendingPathComponent(file)
                        
                        //writing
                        do {
                            try data.write(to: path,
                                           atomically: false,
                                           encoding: String.Encoding.utf8)
                            UserDefaults.standard.set(true,
                                                      forKey: "SessionFilesSavedInDocumentsDirectory")
                        }
                        catch (let error) { print(error.localizedDescription) }
                    }
                }
                catch (let error) { print(error.localizedDescription) }
            }
        }

        Decorator.configureAppearance()
              
        Fabric.with([Crashlytics.self])
        
        if UIApplication.shared.statusBarOrientation != .portrait {
            let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(skipOnBoarding),
                                               name: NSNotification.Name(rawValue: "SkipOnBoarding"),
                                               object: nil)
        
        SDKApplicationDelegate.shared.application(application,
                                                  didFinishLaunchingWithOptions: launchOptions)
        
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        SDKApplicationDelegate.shared.application(app,
                                                  open: url,
                                                  options: options)
        GIDSignIn.sharedInstance().handle(url,
                                          sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                             annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        return true
    }

    func skipOnBoarding() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let initialViewController: UIViewController!
        initialViewController = storyboard.instantiateViewController(withIdentifier: "TabBarViewController")
        self.window?.rootViewController = initialViewController
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        AppEventsLogger.activate()
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        CentralBuetoothManager.shared.cancelConnection()
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if restrictRotation {
            return .portrait
        }
        else {
            return .all
        }
    }
}
