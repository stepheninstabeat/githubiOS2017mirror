//
//  SessionDataTableViewController.swift
//  Instabeat
//
//  Created by Dmytro on 5/18/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit

class SessionDataTableViewController: UITableViewController {
    @IBOutlet var headerView: UIView!
    var session: Session?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dateFormatter = DateFormatter.init()
        dateFormatter.dateFormat = "MMM d"
        let usLocale = NSLocale.init(localeIdentifier: "en_US")
        dateFormatter.locale = usLocale as Locale!
        if let session = session {
            navigationItem.title = dateFormatter.string(from: session.date as Date).uppercased()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIHelper.restrictRotation(restrict: true)
    }
    
    //MARK:Table view data source
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        guard session != nil else { return 0 }
        return session!.laps.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: SessionDataTableViewCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.sessionDataTableViewCellIdentifier) as! SessionDataTableViewCell
        func addBorderToLabel(label: UILabel) {
            label.layer.borderWidth = 0.5
            label.layer.borderColor = Constants.primaryColors.mediumGreyColor.cgColor
        }
        addBorderToLabel(label: cell.lapsLabel)
        addBorderToLabel(label: cell.duration)
        addBorderToLabel(label: cell.stroke)
        addBorderToLabel(label: cell.strokes)
        addBorderToLabel(label: cell.avgHR)
        let lap = session!.laps[indexPath.row]
        cell.lapsLabel.text = String(format: "%03i", Int(lap.lapID))
        cell.duration.text = Utility.secondsToTimeString(lap.duration)
        cell.stroke.text = lap.style
        cell.strokes.text = "\(lap.strokes)"
        cell.avgHR.text = String(lap.averageHR)
        cell.avgHR.textColor = Utility.colorForHeartRateZone(heartRate: Int(lap.averageHR),
                                                             highlightedZone: .none).color
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.backgroundColor = Constants.primaryColors.darkGrayColor
        return cell
    }
    
    // MARK:Table view delegate
    override func tableView(_ tableView: UITableView,
                            heightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
    }
    
    override func tableView(_ tableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {
        headerView.backgroundColor = Constants.primaryColors.mediumGreyColor
        return headerView
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath,
                                         animated: true)
    }
}
