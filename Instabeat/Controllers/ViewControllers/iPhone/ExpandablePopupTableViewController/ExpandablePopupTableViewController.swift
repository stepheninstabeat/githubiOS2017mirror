//
//  ExpandablePopupTableViewController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 7/22/16.
//  Copyright © 2016 GL. All rights reserved.
//
import UIKit
import NAExpandableTableController

class ExpandablePopupTableViewController: UITableViewController, NAExpandableTableViewDataSource, NAExpandableTableViewDelegate {
    
    
    var handleViewController: DashboardViewController!
    var lapsTabSelected = false
    
    var sectionTitles = ["EDIT SESSION", "SHARE"]
    var allOptions:[[String]] = []
    let viewOptions = ["Table View"]
    
    let options = ["Date", "Time", "Pool length"]
    
    let share = ["Facebook",
                 "Twitter",
                 "Email"]
    
    private var expandableTableController: NAExpandableTableController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        allOptions += [options, share]
        if lapsTabSelected {
            sectionTitles.insert("VIEW", at: 0)
            allOptions.insert(viewOptions, at: 0)
        }
        self.view.backgroundColor = Constants.primaryColors.darkGrayColor
        self.expandableTableController = NAExpandableTableController(dataSource: self,
                                                                     delegate: self)
        
        tableView.dataSource = self.expandableTableController
        tableView.delegate = self.expandableTableController
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.reloadData()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navigationController = self.navigationController {
            let navigationBar = navigationController.navigationBar
            let navTopBorder: UIView = UIView(frame: CGRect(x: 0,
                                                            y: 0,
                                                            width: navigationBar.frame.width,
                                                            height: 0.5))
            navTopBorder.backgroundColor = Constants.secondaryColors.whiteColor
            
            let navBotBorder: UIView = UIView(frame: CGRect(x: 0,
                                                            y: navigationBar.frame.size.height,
                                                            width: navigationBar.frame.width,
                                                            height: 0.5))
            navBotBorder.backgroundColor = Constants.primaryColors.mediumGreyColor
            
            self.navigationController?.navigationBar.addSubview(navTopBorder)
            self.navigationController?.navigationBar.addSubview(navBotBorder)
        }
        
    }
    
    // MARK: - NAExpandableTableViewDataSource
    func numberOfSectionsInExpandableTableView(_ tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    func expandableTableView(_ tableView: UITableView,
                             numberOfRowsInSection section: Int) -> Int {
        return allOptions[section].isEmpty ? 0 : allOptions[section].count
    }
    
    public func expandableTableView(_ tableView: UITableView,
                                    cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExpandableCell",
                                                 for: indexPath as IndexPath)
        cell.contentView.backgroundColor = Constants.primaryColors.darkGrayColor
        let textLabel = cell.viewWithTag(4453) as! UILabel
        textLabel.text = allOptions[indexPath.section][indexPath.row]
        return cell
    }
    
    func expandableTableView(_ tableView: UITableView,
                             titleCellForSection section: Int,
                             expanded: Bool) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SectionTitleCell")!
        cell.contentView.backgroundColor = Constants.primaryColors.mediumGreyColor
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        // Configure cell here...
        cell.textLabel?.text = sectionTitles[section]
        return cell
    }
    
    func expandableTableView(_ tableView: UITableView,
                             isExpandableSection section: Int) -> Bool {
        return true
    }
    
    // MARK: - NAExpandableTableViewDelegate
    func expandableTableView(_ tableView: UITableView,
                             didSelectRowAtIndexPath indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cellTitle = allOptions[indexPath.section][indexPath.row]
        switch cellTitle {
        case "Table View":
            handleViewController.openLapsDetails()
        case "Time":
            openEditSessionScreen(type: .time)
        case "Date":
            NotificationCenter.default.addObserver(handleViewController,
                                                   selector: #selector(viewWillAppear(_:)), name: NSNotification.Name(rawValue: "NeedUpdateTitle"), object: nil)
            openEditSessionScreen(type: .date)
        default:
            break
        }
    }
    func openEditSessionScreen(type: TypeOfEditSession) {
        let editSessionViewController = self.storyboard!.instantiateViewController(withIdentifier: "editSessionViewController") as! EditSessionViewController
        editSessionViewController.typeOfEdit = type
        editSessionViewController.session = handleViewController.session
        self.navigationController?.pushViewController(editSessionViewController,
                                                      animated: true)
    }
    @IBAction func dissmissView(_ sender: AnyObject) {
        handleViewController.dismiss(animated: true) {
            self.handleViewController.isBottomMenuOpened = false
        }
    }
    
}
