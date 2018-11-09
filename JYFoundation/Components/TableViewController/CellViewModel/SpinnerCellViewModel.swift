//
//  SpinnerCellViewModel.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/8.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit

public enum SpinnerCellStyle: Int {
    case oval
    case circinal
}

public class SpinnerCellViewModel: TableCellViewModel {
    
    private var _height: CGFloat
    private(set) var tintColor: UIColor
    private(set) var style: SpinnerCellStyle
    
    public static func cellViewModel(with height:CGFloat, tintColor: UIColor = UIColor.gray, style: SpinnerCellStyle = .oval) -> SpinnerCellViewModel {
        return SpinnerCellViewModel(height: height, tintColor: tintColor, style: style)
    }
    
    init(height: CGFloat, tintColor: UIColor, style: SpinnerCellStyle) {
        self._height = height
        self.tintColor = tintColor
        self.style = style
        super.init(nil)
    }
    
    override public func height() -> CGFloat {
        return _height
    }
    
    override public func shouldHighlight() -> Bool {
        return false
    }
    
    override public func cellType() -> JYTableViewCell.Type {
        switch style {
        case .oval:
            return TableOvalSpinnerCell.self
        case .circinal:
            return TableCircinalSpinnerCell.self
        }
    }
}
