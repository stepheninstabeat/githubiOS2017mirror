//
//  EditSessionViewController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 11/4/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit

enum TypeOfEditSession {
    case date, time
}
class EditSessionViewController: UIViewController {
    
    var session: Session!
    var typeOfEdit: TypeOfEditSession = .date
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.setValue(UIColor.white,
                            forKeyPath: "textColor")
        datePicker.setDate(session.date, animated: false)
        switch typeOfEdit {
        case .date:
            datePicker.datePickerMode = .date
        case .time:
            datePicker.datePickerMode = .time
        }
        datePicker.maximumDate = Date()
    }
    
    @IBAction func saveChanges(_ sender: Any) {
        UIHelper.showHUDLoading()
        NetworkManager.shared.updateUserSession(sessionID: session.sessionID,
                                                date: datePicker.date,
                                                successHandler: { (response) in
                                                    UIHelper.dismissHUD()
                                                    DatabaseManager.shared.get(sessionForUser: (self.session.owner?.userID)!,
                                                                               sessionID: self.session.sessionID,
                                                                               success: { (session) in
                                                                                try! DatabaseManager.shared.realm.write {
                                                                                    session.date = self.datePicker.date
                                                                                }
                                                                                if self.typeOfEdit == .date {
                                                                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NeedUpdateTitle"),
                                                                                                                    object: nil)
                                                                                }
                                                    }, failure: nil)
                                                    UIHelper.showAlertControllerWith(title: nil,
                                                                                     message: "Session updated successfully",
                                                                                     inViewController: self, actionButtonTitle: "Ok",
                                                                                     actionHandler: {
                                                                                        _ = self.navigationController?.popViewController(animated: true)
                                                    })
        }, failureHandler: { (error) in
            UIHelper.showAlertControllerWith(title: "Error",
                                             message: error,
                                             inViewController: self, actionButtonTitle: "Ok",
                                             actionHandler: nil)
        })
        //        let file = "\("session " + "\(session.sessionId)").txt" //this is the file. we will write to and read from it
        //
        //
        //        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        //
        //            let path = dir.appendingPathComponent(file)
        //
        //            //reading
        //            do {
        //                let data = try String(contentsOf: path, encoding: String.Encoding.utf8)
        //                var dataArray = data.components(separatedBy: "\n")
        //                let dateString = dataArray[0]
        //                var dateArray = dateString.components(separatedBy: ",")
        //
        //                let dateFormatter = DateFormatter()
        //
        //                dateFormatter.dateFormat = "M,dd,yy"
        //                let newDateString = dateFormatter.string(from: datePicker.date)
        //                let newDateArray = newDateString.components(separatedBy: ",")
        //                dateArray[3] = newDateArray[0]
        //                dateArray[4] = newDateArray[1]
        //                dateArray[5] = newDateArray[2]
        //
        //                dataArray[0] = dateArray.joined(separator: ",")
        //
        //                let stingToSave = dataArray.joined(separator: "\n")
        //                //writing
        //                do {
        //                    try stingToSave.write(to: path, atomically: false, encoding: String.Encoding.utf8)
        //                    UIHelper.showAlertControllerWith(title: nil,
        //                                                     message: "Saved!",
        //                                                     inViewController: self,
        //                                                     actionButtonTitle: "OK",
        //                                                     actionHandler: {
        //                                                        _ = self.navigationController?.popViewController(animated: true)
        //
        //                    })
        ////                    UIHelper.showSuccessHUDWithStatus(status: "Saved!")
        //                }
        //                catch {
        //                    UIHelper.showAlertControllerWith(title: "Error",
        //                                                     message: "Something wrong!",
        //                                                     inViewController: self,
        //                                                     actionButtonTitle: "OK",
        //                                                     actionHandler: nil)
        ////                    UIHelper.showSuccessHUDWithStatus(status: "Something wrong!")
        //
        //                }
        //
        //            }
        //            catch {
        //                UIHelper.showAlertControllerWith(title: "Error",
        //                                                 message: "Something wrong!",
        //                                                 inViewController: self,
        //                                                 actionButtonTitle: "OK",
        //                                                 actionHandler: nil)
        //                
        ////                UIHelper.showSuccessHUDWithStatus(status: "Something wrong!")
        //            }
        //        }
        //        
    }
    
}
