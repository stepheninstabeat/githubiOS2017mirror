//
//  PinkSectionHeaderView.swift
//  JTAppleCalendar
//
//  Created by JayT on 2016-05-11.
//  Copyright © 2016 CocoaPods. All rights reserved.
//
import JTAppleCalendar

class CalendarSectionHeaderView: JTAppleHeaderView {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet weak var leadingSpace: NSLayoutConstraint!
    @IBOutlet var weekdaysLabels: [UILabel]!
}
