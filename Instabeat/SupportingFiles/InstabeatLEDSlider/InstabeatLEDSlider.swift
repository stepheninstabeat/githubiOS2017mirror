//
//  InstabeatLEDSlider.swift
//  Instabeat
//
//  Created by Dmytro Genyk on 11/29/16.
//  Copyright © 2016 GL. All rights reserved.
//
import UIKit

class InstabeatLEDSlider : UISlider {

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let customBounds = CGRect(origin: bounds.origin,
                                  size: CGSize(width: bounds.size.width, height: 8.0))
        super.trackRect(forBounds: customBounds)
        return customBounds
    }

    override func awakeFromNib() {
        self.setThumbImage(UIImage(named: "SliderThumb"), for: .normal)
        super.awakeFromNib()
    }
}
