//
//  JYCollectionViewCell.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/4/30.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit

open class JYCollectionViewCell : UICollectionViewCell {
    
    private(set) open var viewModel: JYCollectionCellViewModel! {
        didSet {
            // update signalBlock
            viewModel.signalBlock = signal
        }
    }
    private(set) var isDisplayed: Bool = false
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    open func updateViewModel(viewModel: JYCollectionCellViewModel) {
        self.viewModel = viewModel
    }
    
    open func willDisappear() {
        isDisplayed = false
    }
    
    open func willDisplay() {
        isDisplayed = true
    }
    
    open func commonInit() {
        // do nothing
    }
    
    private func signal() {
        updateViewModel(viewModel: self.viewModel)
    }
}