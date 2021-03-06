//
//  JYTableViewCell.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/7.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit

open class JYTableViewCell : UITableViewCell {
    
    private(set) open var viewModel: TableCellViewModel! {
        didSet {
            // update signalBlock
            viewModel.signalBlock = signal
        }
    }
    private(set) var isDisplayed: Bool = false
    
    override public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    open func updateViewModel(viewModel: TableCellViewModel) {
        self.viewModel = viewModel
    }
    
    public func willDisappear() {
        isDisplayed = false
    }
    
    public func willDisplay() {
        isDisplayed = true
    }
    
    open func commonInit() {
        // do nothing
    }
    
    private func signal() {
        updateViewModel(viewModel: self.viewModel)
    }
}
