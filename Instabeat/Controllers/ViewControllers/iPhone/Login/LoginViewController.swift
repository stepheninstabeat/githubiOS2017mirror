//
//  LoginViewController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 10/20/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import FacebookCore
import FacebookLogin
import GGLSignIn
import GoogleSignIn

class LoginViewController: UIViewController, UITextFieldDelegate, GIDSignInDelegate, GIDSignInUIDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    private var textFieldsArray: [UITextField]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        if let _ = AccessToken.current?.authenticationToken {
            for subview in view.subviews {
                subview.isHidden = true
            }
            loginUserWithFacebook()
        } else if let userEmail =  KeychainWrapper.standard.string(forKey: "InstabeatUserEmail"),
            let userPassword = KeychainWrapper.standard.string(forKey: "InstabeatUserPassword") {
            for subview in view.subviews {
                subview.isHidden = true
            }
            loginUser(email: userEmail,
                      password: userPassword)
        } else if GIDSignIn.sharedInstance().hasAuthInKeychain() {
            UIHelper.showHUDLoading()
            GIDSignIn.sharedInstance().signInSilently()
        }
        textFieldsArray = [
            emailTextField,
            passwordTextField
        ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: NSNotification.Name.UIKeyboardWillShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: NSNotification.Name.UIKeyboardWillHide,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideKeyboard(self)
        self.navigationController?.isNavigationBarHidden = false
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.UIKeyboardWillShow,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.UIKeyboardWillHide,
                                                  object: nil)
    }
    
    @IBAction func login(_ sender: AnyObject) {
        if (passwordTextField.text?.isEmpty)! ||
            (emailTextField.text?.isEmpty)! ||
            !Utility.isValid(email: emailTextField.text!) {
            UIHelper.showAlertControllerWith(title: "Sign In Failed",
                                             message: "Email or Password cannot be validated. Please try again.",
                                             inViewController: self,
                                             actionButtonTitle: "OK",
                                             actionHandler: nil)
            return
        }
        
        self.hideKeyboard(self)
        loginUser(email: emailTextField.text!,
                  password: passwordTextField.text!)
    }
    
    private func loginUser(email: String,
                           password: String) {
        UIHelper.showHUDLoading()
        LoginManager().logOut()
        GIDSignIn.sharedInstance().signOut()
        NetworkManager.shared.loginUser(email: email,
                                        password: password,
                                        successHandler: { (token, userID) in
                                            self.getUserInfo(isFirstTimeLogged: nil,
                                                             token: token,
                                                             userID: userID)
        }, failureHandler: { errorString in
            UIHelper.dismissHUD()
            UIHelper.showAlertControllerWith(title: "Login failed",
                                             message: errorString,
                                             inViewController: self,
                                             actionButtonTitle: "OK",
                                             actionHandler: {
                                                for subview in self.view.subviews {                                                     subview.isHidden = false
                                                }
            })
        })
    }
    
    private func loginUserWithFacebook() {
        let parameters = ["fields" : "email, first_name, last_name"]
        let graphRequest = GraphRequest(graphPath: "me",
                                        parameters: parameters)
        graphRequest.start({ (response, requestResult) in
            switch requestResult {
            case .failed(let error):
                print(error.localizedDescription)
                break
            case .success(let graphResponse):
                if let responseDictionary = graphResponse.dictionaryValue {
                    guard let userID = responseDictionary["id"] as? String,
                        let accessToken = AccessToken.current?.authenticationToken else {
                            return
                    }
                    UIHelper.showHUDLoading()
                    NetworkManager.shared.loginUser(facebookUserID: userID,
                                                    facebookUserToken: accessToken,
                                                    email: responseDictionary["email"] as! String,
                                                    firstName: responseDictionary["first_name"] as? String ?? "",
                                                    lastName: responseDictionary["last_name"] as? String ?? "",
                                                    successHandler: { (token, userID, isFirstTime) in
                                                        self.getUserInfo(isFirstTimeLogged: isFirstTime,
                                                                         token: token,
                                                                         userID: userID)
                    }, failureHandler: { error in
                        LoginManager().logOut()
                        UIHelper.showAlertControllerWith(title: "Login Failed!",
                                                         message: error,
                                                         inViewController: self,
                                                         actionButtonTitle: "OK",
                                                         actionHandler: {
                                                            for subview in self.view.subviews {
                                                                subview.isHidden = false
                                                            }
                                                         })
                    })
                }
            }
        })
    }
    
    private func getUserInfo(isFirstTimeLogged: Bool?,
                             token: String,
                             userID: String) {
        UIHelper.dismissHUD()
        DatabaseManager.shared.get(user: userID,
                                   success: { user in
                                    DataStorage.shared.activeUser = user
                                    
                                    DatabaseManager.shared.realm.beginWrite()
                                    DataStorage.shared.activeUser.token = token
                                    do {
                                        try DatabaseManager.shared.realm.commitWrite()
                                        DatabaseManager.shared.save(user: user,
                                                                    failure: nil)
                                    }
                                    catch (let error){ print(error.localizedDescription) }
                                    if user.instabeatHardwareVersion != "" {
                                        CentralBuetoothManager.shared.scan()
                                    }
                                    self.getUserSessions()
        },
                                   failure: { error in
                                    UIHelper.showHUDLoading()
                                    NetworkManager.shared.getUser(userToken: token,
                                                                  successHandler: { user in
                                                                    DatabaseManager.shared.save(user: user,
                                                                                                failure: nil)
                                                                    DatabaseManager.shared.get(user: user.userID,
                                                                                               success: { user in
                                                                                                DataStorage.shared.activeUser = user
                                                                    },
                                                                                               failure: nil)
                                                                    let storyboard = UIStoryboard(name: "Main",
                                                                                                  bundle: nil)
                                                                    
                                                                    if user.instabeatHardwareVersion != "" {
                                                                        CentralBuetoothManager.shared.scan()
                                                                    }
                                                                    if isFirstTimeLogged ?? false {
                                                                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                                                        appDelegate.window?.rootViewController = storyboard.instantiateViewController(withIdentifier: "NavLandingPageViewController")
                                                                    } else {
                                                                        self.getUserSessions()
                                                                    }
                                    },
                                                                  failureHandler: { error in
                                                                    UIHelper.dismissHUD()
                                                                    UIHelper.showAlertControllerWith(title: "Error",
                                                                                                     message: error,
                                                                                                     inViewController: self,
                                                                                                     actionButtonTitle: "OK",
                                                                                                     actionHandler: nil)
                                    })
                                    
        })
    }
    
    func getUserSessions () {
        UIHelper.showHUDLoading()
        NetworkManager.shared.getUserSessionsList(userID: DataStorage.shared.activeUser.userID,
                                                  token: DataStorage.shared.activeUser.token,
                                                  successHandler: { sessionIDs in
                                                    DataCoordinator.downloadUserSessions(userID: DataStorage.shared.activeUser.userID,
                                                                                         token: DataStorage.shared.activeUser.token,
                                                                                         sessionsIDs: sessionIDs,
                                                                                         completted: {
                                                                                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                                                                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                                                                            appDelegate.window?.rootViewController = storyboard.instantiateViewController(withIdentifier: "TabBarViewController")
                                                    })
        }, failureHandler: { error in
            UIHelper.dismissHUD()
            UIHelper.showAlertControllerWith(title: "Error",
                                             message: error,
                                             inViewController: self,
                                             actionButtonTitle: "OK",
                                             actionHandler: {
                                                for subview in self.view.subviews {
                                                    subview.isHidden = false
                                                }
                                             })
        })
    }
    
    @IBAction func forgotPassword(_ sender: UIButton) {
        self.performSegue(withIdentifier: "openForgotPasswordViewController",
                          sender: self)
    }
    
    @IBAction func signUp(_ sender: UIButton) {
        self.performSegue(withIdentifier: "openSignUpViewController",
                          sender: self)
    }
    
    //MARK: Login With Facebook
    @IBAction func loginWithFacebook(_ sender: UIButton) {
        GIDSignIn.sharedInstance().signOut()
        KeychainWrapper.standard.removeObject(forKey: "InstabeatUserEmail")
        KeychainWrapper.standard.removeObject(forKey: "InstabeatUserPassword")
        LoginManager().logIn([
            .publicProfile,
            .email,
            .userFriends
            ],
                             viewController: self) { loginResult in
                                switch loginResult {
                                case .failed(let error):
                                    print(error)
                                case .cancelled:
                                    print("User cancelled login.")
                                case .success:
                                    self.loginUserWithFacebook()
                                    print("Logged in!")
                                }
        }
    }
    
    //MARK: Login With Google Plus
    @IBAction func loginWithGooglePlus(_ sender: UIButton) {
        LoginManager().logOut()
        KeychainWrapper.standard.removeObject(forKey: "InstabeatUserEmail")
        KeychainWrapper.standard.removeObject(forKey: "InstabeatUserPassword")
        GIDSignIn.sharedInstance().signIn()
    }

    public func sign(_ signIn: GIDSignIn!,
                     didSignInFor user: GIDGoogleUser!,
                     withError error: Error!) {
        if (error == nil) {
            // Perform any operations on signed in user here.
            if let userId = user.userID,
                let idToken = user.authentication.idToken,
                let givenName = user.profile.givenName,
                let familyName = user.profile.familyName,
                let email = user.profile.email {
                UIHelper.showHUDLoading()
                NetworkManager.shared.loginUser(googlePlusUserID: userId,
                                                googlePlusUserToken: idToken,
                                                email: email,
                                                firstName: givenName,
                                                lastName: familyName,
                                                successHandler: { (token, userID, isFirstTime) in
                                                    self.getUserInfo(isFirstTimeLogged: isFirstTime,
                                                                     token: token,
                                                                     userID: userID)
                }, failureHandler: { error in
                    GIDSignIn.sharedInstance().signOut()
                    UIHelper.showAlertControllerWith(title: "Login Failed!",
                                                     message: error,
                                                     inViewController: self,
                                                     actionButtonTitle: "OK",
                                                     actionHandler: {
                                                        for subview in self.view.subviews {
                                                            subview.isHidden = false
                                                        }
                                                     })
                })
            }
        } else { print(error.localizedDescription) }
    }
    func sign(_ signIn: GIDSignIn!,
              didDisconnectWith user:GIDGoogleUser!,
              withError error: Error!) {
        print("logged out G+ user \(user.userID)")
        // Perform any operations when the user disconnects from app here.
    }
    @IBAction func hideKeyboard(_ sender: AnyObject) {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    //MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "openForgotPasswordViewController":
            let forgotPasswordViewController = segue.destination as! ForgotPasswordViewController
            forgotPasswordViewController.email = emailTextField.text
        default:
            break
        }
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField != textFieldsArray.last!,
            let indexOfTextField = textFieldsArray.index(of: textField){
            textFieldsArray[indexOfTextField + 1].becomeFirstResponder()
        }
        else {
            login(self)
        }
        return true
    }
    
    func keyboardWillShow(sender: NSNotification) {
        let userInfo = sender.userInfo!
        
        let keyboardSize: CGSize = (userInfo[UIKeyboardFrameBeginUserInfoKey]! as AnyObject).cgRectValue.size
        let offset: CGSize = (userInfo[UIKeyboardFrameEndUserInfoKey]! as AnyObject).cgRectValue.size
        
        if keyboardSize.height == offset.height {
            if self.view.frame.origin.y == 0 {
                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                    self.view.frame.origin.y -= keyboardSize.height
                })
            }
        } else {
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.view.frame.origin.y += keyboardSize.height - offset.height
            })
        }
    }
    
    func keyboardWillHide(sender: NSNotification) {
        let userInfo = sender.userInfo!
        let keyboardSize: CGSize = (userInfo[UIKeyboardFrameBeginUserInfoKey]! as AnyObject).cgRectValue.size
        self.view.frame.origin.y += keyboardSize.height
    }
}
