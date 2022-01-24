//
//  JYCellViewModel.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/7.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit

public class JYTableViewCellAction {
    var key: String
    var title: String
    var style: UITableViewRowAction.Style
    var userInfo: Any?
    
    public init(key: String, title: String, style: UITableViewRowAction.Style, userInfo: Any? = nil) {
        self.key = key
        self.title = title
        self.style = style
        self.userInfo = userInfo
    }
}

open class JYTableCellViewModel: NSObject, ICellViewModel {
    private(set) public var model: Any? = nil
    
    public init(_ model: Any?) {
        self.model = model
    }
    
    public convenience override init() {
        self.init(nil)
    }
    
    public var signalBlock: (()->())? = nil
    public var notificationBlock: ((JYTableCellViewModel, String, Any?) -> Void)? = nil
    
    open func height() -> CGFloat {
        return 0
    }
    
    open func shouldHighlight() -> Bool {
        return true
    }
    
    open func cellType() -> JYTableViewCell.Type {
        return JYTableViewCell.self
    }

    open func actionButtons() -> [JYTableViewCellAction]? {
        return nil
    }

    open func didSelect() {
        // do nothing
    }
    
    // MARK: publics
    
    public func update() {
        signalBlock?()
    }
    
    public func notification(identifier: String, userInfo: Any? = nil) {
        notificationBlock?(self, identifier, userInfo)
    }
}