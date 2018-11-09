//
//  SeparatorCell.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/7.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit


public class SeparatorCell : JYTableViewCell {
    
    private var separatorView: UIView!

    public override func commonInit() {
        separatorView = UIView()
        addSubview(separatorView)
    }
    
    override public func updateViewModel(viewModel: TableCellViewModel) {
        super.updateViewModel(viewModel: viewModel)
        if let viewModel = viewModel as? SeparatorCellViewModel {
            separatorView.backgroundColor = viewModel.separatorColor
            separatorView.frame = CGRect(x: viewModel.separatorInsets.left,
                                         y: 0,
                                         width: self.frame.width - viewModel.separatorInsets.left - viewModel.separatorInsets.right,
                                         height: self.frame.height)
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if let viewModel = viewModel as? SeparatorCellViewModel {
            separatorView.frame = CGRect(x: viewModel.separatorInsets.left,
                                         y: 0,
                                         width: self.frame.width - viewModel.separatorInsets.left - viewModel.separatorInsets.right,
                                         height: self.frame.height)
        }
    }
}
