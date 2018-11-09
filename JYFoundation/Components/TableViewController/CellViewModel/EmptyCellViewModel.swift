//
//  EmptyCellViewModel.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/7.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit


public class EmptyCellViewModel : TableCellViewModel {
    
    private var _height: CGFloat
    private(set) var backgroundColor: UIColor
    
    public static func cellViewModel(with height:CGFloat, backgroundColor: UIColor = UIColor.clear) -> EmptyCellViewModel {
        return EmptyCellViewModel(height: height, backgroundColor: backgroundColor)
    }
    
    init(height: CGFloat, backgroundColor: UIColor) {
        self._height = height
        self.backgroundColor = backgroundColor
        super.init(nil)
    }
    
    override public func height() -> CGFloat {
        return _height
    }
    
    override public func shouldHighlight() -> Bool {
        return false
    }
    
    override public func cellType() -> JYTableViewCell.Type {
        return EmptyCell.self
    }
}
