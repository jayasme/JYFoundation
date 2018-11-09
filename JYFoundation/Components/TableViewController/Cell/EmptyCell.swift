//
//  EmptyCell.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/7.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit

public class EmptyCell: JYTableViewCell {

    override public func updateViewModel(viewModel: TableCellViewModel) {
        super.updateViewModel(viewModel: viewModel)
        if let viewModel = viewModel as? EmptyCellViewModel {
            self.backgroundColor = viewModel.backgroundColor
        }
    }
}
