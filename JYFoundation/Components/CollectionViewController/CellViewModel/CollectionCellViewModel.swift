//
//  CollectionCellViewModel.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/4/30.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation

open class CollectionCellViewModel: NSObject, ICellViewModel {
    private(set) public var model: Any? = nil
    
    public init(_ model: Any?) {
        self.model = model
    }
    
    public convenience override init() {
        self.init(nil)
    }
    
    public var signalBlock: (()->())? = nil
    public var notificationBlock: ((CollectionCellViewModel, String, Any?) -> Void)? = nil
    
    open func size() -> CGSize {
        return CGSize(width: 50, height: 50)
    }
    
    open func shouldHighlight() -> Bool {
        return true
    }
    
    open func cellType() -> JYCollectionViewCell.Type {
        return JYCollectionViewCell.self
    }
    
    open func deletionTitle() -> String? {
        return nil
    }
    
    open func didSelect() {
        // do nothing
    }
    
    open func didDelete() {
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
