//
//  CircinalSpinnerHeaderView.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/4/30.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation

public class CollectionCircinalSpinnerView: UICollectionReusableView {
    
    @IBOutlet weak var spinnerIndicator: ONCircinalActivityIndicator!
    
    public func willDisplay() {
        spinnerIndicator.startAnimation()
    }
    
    public func willDisappear() {
        spinnerIndicator.stopAnimation()
    }
}
