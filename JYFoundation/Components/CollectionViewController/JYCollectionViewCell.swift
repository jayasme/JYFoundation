//
//  JYCollectionViewCell.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/4/30.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit

open class JYCollectionViewCell : UICollectionViewCell, JYThemeful {
    
    private(set) open var viewModel: ICollectionCellViewModel! {
        didSet {
            // update signalBlock
            viewModel.signalBlock = signal
            viewModel.cell = self
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
    
    open func updateViewModel(viewModel: ICollectionCellViewModel) {
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
    
    // MARK: JYThemeful
    
    public var themes: [JYTheme] = [] {
        didSet {
            self.passthroughThemes()
        }
    }
    
    public var styleSheet: JYStyleSheet? = nil {
        didSet {
            self.passthroughThemes()
        }
    }
    
    private func passthroughThemes() {
        passthroughSubThemes(view: self)
        for subview in self.contentView.subviews {
            passthroughSubThemes(view: subview)
        }
    }
    
    private func passthroughSubThemes(view: UIView) {
        if let view = view as? JYThemeful {
            view.themes = self.themes
        }
        for subview in self.subviews {
            passthroughSubThemes(view: subview)
        }
    }
}
