//
//  JYCollectionCellViewModel.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/4/30.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import UIKit

@objc public protocol ICollectionCellViewModel: AnyObject {
    func notification(identifier: String, userInfo: Any?)
    func updateCell()
    func cellType() -> JYCollectionViewCell.Type
    func size() -> CGSize
    func shouldHighlight() -> Bool
    func isDraggable(draggingCellViewModel: ICollectionCellViewModel?) -> Bool
    func didSelect()
    
    var signalBlock: (()->())? { get set }
    var notificationBlock: ((ICollectionCellViewModel, String, Any?) -> Void)? { get set }
    var cell: JYCollectionViewCell? { get set }
}

open class JYCollectionCellViewModel<T>: NSObject, ICollectionCellViewModel {
    public var model: T {
        didSet {
            self.updateModel(self.model)
            self.signalBlock?()
        }
    }
    
    public weak var cell: JYCollectionViewCell? = nil
    
    public init(_ model: T) {
        self.model = model
        super.init()
        self.updateModel(model)
    }
    
    public var signalBlock: (()->())? = nil
    public var notificationBlock: ((ICollectionCellViewModel, String, Any?) -> Void)? = nil
    
    open func size() -> CGSize {
        return .zero
    }
    
    /// Indicates wheter the cell view model is reacted to dragging, if draggingCellViewModel is nil means current cell view model is dragging cell view model.
    open func isDraggable(draggingCellViewModel: ICollectionCellViewModel?) -> Bool {
        return false
    }
    
    open func shouldHighlight() -> Bool {
        return true
    }
    
    open func cellType() -> JYCollectionViewCell.Type {
        return JYCollectionViewCell.self
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
    
    public func updateCell() {
        self.signalBlock?()
    }
}
