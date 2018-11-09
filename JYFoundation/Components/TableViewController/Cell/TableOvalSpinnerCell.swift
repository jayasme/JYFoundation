//
//  TableOvalSpinnerCell.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/8.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit

public class TableOvalSpinnerCell: JYTableViewCell {
    
    @IBOutlet weak var spinnerIndicator: ONOvalActivityIndicator!
    
    override public func willDisplay() {
        spinnerIndicator.startAnimation()
    }
    
    override public func willDisappear() {
        spinnerIndicator.stopAnimation()
    }
    
}
