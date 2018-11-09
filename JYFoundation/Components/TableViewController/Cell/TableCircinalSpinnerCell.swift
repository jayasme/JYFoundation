//
//  CircinalSpinnerCell.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/26.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit

public class TableCircinalSpinnerCell: JYTableViewCell {
    
    @IBOutlet weak var spinnerIndicator: ONCircinalActivityIndicator!
    
    override public func willDisplay() {
        spinnerIndicator.startAnimation()
    }
    
    override public func willDisappear() {
        spinnerIndicator.stopAnimation()
    }
}
