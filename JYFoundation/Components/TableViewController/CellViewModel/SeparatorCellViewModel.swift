//
//  SeparatorCellViewModel.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/7.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit


public class SeparatorCellViewModel: TableCellViewModel {

    private(set) var separatorInsets: UIEdgeInsets
    private(set) var separatorColor: UIColor
    
    public static func cellViewModel(separatorInsets: UIEdgeInsets = UIEdgeInsets.zero, separatorColor: UIColor = UIColor.hexColor(0xf8f8f8)) -> SeparatorCellViewModel {
        return SeparatorCellViewModel(separatorInsets: separatorInsets, separatorColor: separatorColor)
    }
    
    public init(separatorInsets: UIEdgeInsets, separatorColor: UIColor) {
        self.separatorInsets = separatorInsets
        self.separatorColor = separatorColor
        super.init(nil)
    }
    
    override public func height() -> CGFloat {
        return 1
    }
    
    override public func shouldHighlight() -> Bool {
        return false
    }
    
    override public func cellType() -> JYTableViewCell.Type {
        return SeparatorCell.self
    }
}
