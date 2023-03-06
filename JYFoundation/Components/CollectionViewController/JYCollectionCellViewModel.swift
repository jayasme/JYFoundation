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
    func didSelect()
    
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
    
    internal var signalBlock: (()->())? = nil
    internal var notificationBlock: ((ICollectionCellViewModel, String, Any?) -> Void)? = nil
    
    open func size() -> CGSize {
        return .zero
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
