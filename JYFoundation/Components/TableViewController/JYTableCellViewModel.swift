//
//  JYCellViewModel.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/7.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit

public class JYTableViewCellAction: NSObject {
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

@objc public protocol ITableCellViewModel: AnyObject {
    func notification(identifier: String, userInfo: Any?)
    func cellType() -> JYTableViewCell.Type
    func height() -> CGFloat
    func isDraggable() -> Bool
    func shouldHighlight() -> Bool
    func actionButtons() -> [JYTableViewCellAction]?
    func didSelect()
    
    var signalBlock: (()->())? { get set }
    var notificationBlock: ((ITableCellViewModel, String, Any?) -> Void)? { get set }
    var cell: JYTableViewCell? { get set }
}

open class JYTableCellViewModel<T>: NSObject, ITableCellViewModel {
    public var model: T {
        didSet {
            self.updateModel(self.model)
            self.signalBlock?()
        }
    }
    
    public weak var cell: JYTableViewCell? = nil
    
    public init(_ model: T) {
        self.model = model
        super.init()
        self.updateModel(model)
    }
    
    public var signalBlock: (()->())? = nil
    public var notificationBlock: ((ITableCellViewModel, String, Any?) -> Void)? = nil
    
    // MARK: Overrides
    
    open func height() -> CGFloat {
        return 0
    }
    
    open func isDraggable() -> Bool {
        return false
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
    
    open func updateModel(_ model: T) {
        // do nothing
    }
    
    // MARK: publics
    
    public func notification(identifier: String, userInfo: Any? = nil) {
        notificationBlock?(self, identifier, userInfo)
    }
}


open class JYSimpleTableCellViewModel: NSObject, ITableCellViewModel {
    public weak var cell: JYTableViewCell? = nil
    
    public var signalBlock: (()->())? = nil
    public var notificationBlock: ((ITableCellViewModel, String, Any?) -> Void)? = nil
    
    // MARK: Overrides
    
    open func height() -> CGFloat {
        return 0
    }
    
    open func isDraggable() -> Bool {
        return false
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
    
    public func notification(identifier: String, userInfo: Any? = nil) {
        notificationBlock?(self, identifier, userInfo)
    }
}
