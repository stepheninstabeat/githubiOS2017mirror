//
//  CalendarCellView.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 8/12/16.
//  Copyright © 2016 GL. All rights reserved.
//
import JTAppleCalendar

class CalendarCellView: JTAppleDayCellView {
    @IBInspectable var todayColor: UIColor!// = UIColor(red: 254.0/255.0, green: 73.0/255.0, blue: 64.0/255.0, alpha: 0.3)
    @IBInspectable var normalDayColor: UIColor! //UIColor(white: 0.0, alpha: 0.1)
    var dayLabel: UILabel!
    
    @IBOutlet weak var startBarChartView: UIView!
    @IBOutlet weak var sessionBarChartView: UIView!
    @IBOutlet weak var endBarChartView: UIView!
    
    var session: Session?
    
    lazy var todayDate : String = {
        [weak self] in
        let aString = self!.c.string(from: NSDate() as Date)
        return aString
    }()
    lazy var c : DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        
        return f
    }()
    
    func setupCellBeforeDisplay(_ cellState: CellState, date: Date) {
        // Setup Cell text
        dayLabel.text =  cellState.text
        self.viewWithTag(5678)?.removeFromSuperview() //current day view
                // Setup Cell Background color
        dayLabel.textColor = Constants.primaryColors.whiteColor
        if c.string(from: date as Date) == todayDate {
            dayLabel.textColor = Constants.primaryColors.darkGrayColor
//            dayLabel.textColor = UIColor.red
            let currentDayView = UIView()
            currentDayView.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
            currentDayView.center = dayLabel.center
            currentDayView.backgroundColor = Constants.secondaryColors.whiteColor
            currentDayView.layer.cornerRadius = dayLabel.frame.width / 2
            currentDayView.tag = 5678
            self.insertSubview(currentDayView, at: 0)
        }
        startBarChartView.backgroundColor = UIColor.darkGray
        sessionBarChartView.backgroundColor = UIColor.darkGray
        endBarChartView.backgroundColor = UIColor.darkGray
        if let session = session {
            let averageColor = Utility.colorForHeartRateZone(heartRate: session.averageHeartRate,
                                                             highlightedZone: .none).color
            startBarChartView.backgroundColor = averageColor
            sessionBarChartView.backgroundColor = averageColor
            endBarChartView.backgroundColor = averageColor
        }
        // Configure Visibility
        configureVisibility(cellState)
    }
    
    func configureVisibility(_ cellState: CellState) {
        if cellState.dateBelongsTo == .thisMonth {
            self.isHidden = false
        } else {
            self.isHidden = true
        }
    }
}
