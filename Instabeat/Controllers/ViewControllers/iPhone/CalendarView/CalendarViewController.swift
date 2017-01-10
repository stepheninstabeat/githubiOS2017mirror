//
//  CalendarViewController.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 8/12/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit
import JTAppleCalendar

class CalendarViewController: UIViewController, JTAppleCalendarViewDelegate, JTAppleCalendarViewDataSource {
    
    weak var calendarView: JTAppleCalendarView!
    private var elderSessionDate = Date()
    private var latestSessionDate = Date()
    var numberOfRows = 6
    let formatter = DateFormatter()
    var calendarInstance = Calendar.current
    var generateInDates: InDateCellGeneration = .forAllMonths
    var generateOutDates: OutDateCellGeneration = .tillEndOfGrid
    let firstDayOfWeek: DaysOfWeek = .sunday
    let disabledColor = UIColor.lightGray
    let enabledColor = UIColor.blue
    let dateCellSize: CGFloat? = nil
    private var shouldDisplayNavigationTitle = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false

        calendarView.alpha = 0
        calendarView.direction = .vertical
        generateOutDates = .tillEndOfGrid
        generateInDates = .forAllMonths
        formatter.dateFormat = "yyyy MM dd"
        
        calendarInstance.timeZone = NSTimeZone.local
        calendarView.delegate = self
        calendarView.dataSource = self
        calendarView.registerCellViewXib(file: "CalendarCellView")
        calendarView.cellInset = CGPoint(x: 0,
                                         y: 0)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(setupCalendarData),
                                               name: NSNotification.Name(rawValue: "NewSessionsAvailable"),
                                               object: nil)
        setupCalendarData()
        let month = calendarInstance.dateComponents([.month],
                                                    from: Date()).month!
        let monthName = DateFormatter().monthSymbols[(month - 1) % 12]
        let year = calendarInstance.component(.year, from:  Date())
        navigationItem.title = monthName.uppercased() + " " + String(year)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIHelper.restrictRotation(restrict: true)
        if UIApplication.shared.statusBarOrientation != .portrait {
            let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
        }
    }
    
    func setupCalendarData() {
        if let latestSessionDate = DataStorage.shared.activeUser.sessions.last?.date,
            let elderSessionDate = DataStorage.shared.activeUser.sessions.first?.date {
            self.latestSessionDate = latestSessionDate
            self.elderSessionDate = elderSessionDate
        }
        
        self.calendarView.visibleDates { (visibleDates: DateSegmentInfo) in
            self.shouldDisplayNavigationTitle = true
            self.calendarView.scrollToDate(Date(),
                                           triggerScrollToDateDelegate: true,
                                           animateScroll: true,
                                           preferredScrollPosition: nil,
                                           completionHandler: {
                                            self.calendarView.alpha = 1.0
                                            self.calendarView.reloadData()
            })
        }
    }
    
    func setupViewsOfCalendar(from visibleDates: DateSegmentInfo) {
        guard let startDate = visibleDates.monthDates.first else {
            return
        }
        if !shouldDisplayNavigationTitle {
            return
        }
        let month = calendarInstance.dateComponents([.month],
                                                    from: startDate).month!
        let monthName = DateFormatter().monthSymbols[(month - 1) % 12]
        let year = calendarInstance.component(.year, from: startDate)
        navigationItem.title = monthName.uppercased() + " " + String(year)
    }
    
    // MARK : JTAppleCalendarDelegate

    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        let startDate = self.elderSessionDate
        let endDate = Date()
        let parameters = ConfigurationParameters(startDate: startDate,
                                                 endDate: endDate,
                                                 numberOfRows: numberOfRows,
                                                 calendar: calendarInstance,
                                                 generateInDates: generateInDates,
                                                 generateOutDates: generateOutDates,
                                                 firstDayOfWeek: firstDayOfWeek)
        return parameters
    }
    
    func calendar(_ calendar: JTAppleCalendarView,
                  willDisplayCell cell: JTAppleDayCellView,
                  date: Date,
                  cellState: CellState) {
        let cell = cell as! CalendarCellView
        cell.session = nil
        for session in DataStorage.shared.activeUser.sessions {
            let sameDate = NSCalendar.current.isDate(session.date,
                                                     inSameDayAs: date)
            if sameDate {
                cell.session = session
            }
        }
        cell.setupCellBeforeDisplay(cellState,
                                    date: date)
    }
    
    
    
    func calendar(_ calendar: JTAppleCalendarView,
                  didSelectDate date: Date,
                  cell: JTAppleDayCellView?,
                  cellState: CellState) {
        let cell = cell as! CalendarCellView
        
        if let session = cell.session {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "showMainScreenSegueIdentifier",
                                  sender: session)
            }
        }
    }
    
    func calendar(_ calendar: JTAppleCalendarView,
                  didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        self.setupViewsOfCalendar(from: visibleDates)
        //setupViewsOfCalendar(startDate: startDate, endDate: endDate)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {
        switch segue.identifier! {
        case "showMainScreenSegueIdentifier":
            let destination: DashboardViewController = segue.destination as! DashboardViewController
            destination.session = sender as! Session
        default:
            break
        }
    }
}


