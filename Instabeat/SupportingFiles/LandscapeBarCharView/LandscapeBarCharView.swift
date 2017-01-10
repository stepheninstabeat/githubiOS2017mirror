//
//  LandscapeBarCharView.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 8/26/16.
//  Copyright © 2016 GL. All rights reserved.
//

import UIKit

class LandscapeBarCharView : UIView {
    
    var shouldDisplayTitle = true
    var titleLabel: UILabel!
    var endChartView: UIView!
    var chartView: HorizontalBarChartView!
    var startChartView: UIView!
    
    override init (frame : CGRect) {
        super.init(frame : frame)
    }
    
    convenience init () {
        self.init(frame:CGRect.zero)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setup() {
        self.backgroundColor = UIColor.clear
        self.clipsToBounds = true
        
        chartView = HorizontalBarChartView()
        chartView.noDataText = " "
        chartView.clipsToBounds = true
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.isUserInteractionEnabled = false
        self.addSubview(chartView)
        
        startChartView = UIView()
        startChartView.clipsToBounds = true
        startChartView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(startChartView)
        
        endChartView = UIView()
        endChartView.clipsToBounds = true
        endChartView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(endChartView)
        
        func addConstraint(attribute: NSLayoutAttribute, toView view: UIView, constant: CGFloat) {
            self.addConstraint(NSLayoutConstraint(
                item: view,
                attribute: attribute,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1,
                constant: constant))
        }
        
        func addCenterXConstraintToView(view: UIView) {
            self.addConstraint(NSLayoutConstraint(item: view,
                attribute: .centerX,
                relatedBy: .equal,
                toItem: self,
                attribute: .centerX,
                multiplier: 1,
                constant: 0))
        }
        
        func addCenterYConstraintToView(view: UIView) {
            self.addConstraint(NSLayoutConstraint(item: view,
                attribute: .centerY,
                relatedBy: .equal,
                toItem: self,
                attribute: .centerY,
                multiplier: 1,
                constant: 0))
        }
        
        if shouldDisplayTitle {
            titleLabel = UILabel()
            titleLabel.font = Constants.fonts.blenderMedium
            titleLabel.textColor = Constants.primaryColors.whiteColor
            titleLabel.numberOfLines = 0
            titleLabel.textAlignment = .center
            titleLabel.backgroundColor = Constants.primaryColors.darkGrayColor
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(titleLabel)
            
            addConstraint(attribute: .height, toView: titleLabel, constant: 40)
            addConstraint(attribute: .width, toView: titleLabel, constant: 40)
            addCenterYConstraintToView(view: titleLabel)
            self.addConstraint(NSLayoutConstraint(item: titleLabel,
                attribute: .leading,
                relatedBy: .equal,
                toItem: self,
                attribute: .leading,
                multiplier: 1,
                constant: 0))
            
            self.addConstraint(NSLayoutConstraint(item: startChartView,
                attribute: .leading,
                relatedBy: .equal,
                toItem: titleLabel,
                attribute: .trailing,
                multiplier: 1,
                constant: 0))
            
            self.addConstraint(NSLayoutConstraint(item: chartView,
                attribute: .leading,
                relatedBy: .equal,
                toItem: startChartView,
                attribute: .leading,
                multiplier: 1,
                constant: -6))
        }
        else {
            self.addConstraint(NSLayoutConstraint(item: startChartView,
                attribute: .leading,
                relatedBy: .equal,
                toItem: self,
                attribute: .leading,
                multiplier: 1,
                constant: 0))
            
            self.addConstraint(NSLayoutConstraint(item: chartView,
                attribute: .leading,
                relatedBy: .equal,
                toItem: startChartView,
                attribute: .trailing,
                multiplier: 1,
                constant: -6))
        }
        
        
        addConstraint(attribute: .height, toView: startChartView, constant: 24)
        addConstraint(attribute: .width, toView: startChartView, constant: 5)
        addCenterYConstraintToView(view: startChartView)
        
        addConstraint(attribute: .height, toView: endChartView, constant: 24)
        addConstraint(attribute: .width, toView: endChartView, constant: 5)
        addCenterYConstraintToView(view: endChartView)
        
        addConstraint(attribute: .height, toView: chartView, constant: 40)
        addCenterYConstraintToView(view: chartView)
        
        self.addConstraint(NSLayoutConstraint(item: chartView,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: endChartView,
            attribute: .trailing,
            multiplier: 1,
            constant: 6))
        
        self.addConstraint(NSLayoutConstraint(item: endChartView,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: self,
            attribute: .trailing,
            multiplier: 1,
            constant: 0))
    }
}
