//
//  JYCollectionCellViewModel.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/4/30.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import UIKit

open class JYCollectionCellViewModel: NSObject, ICellViewModel {
    public var model: Any? = nil {
        didSet {
            self.update(self.model)
        }
    }
    
    public init(_ model: Any?) {
        super.init()
        self.model = model
        self.update(model)
    }
    
    public convenience override init() {
        self.init(nil)
    }
    
    public var signalBlock: (()->())? = nil
    public var notificationBlock: ((JYCollectionCellViewModel, String, Any?) -> Void)? = nil
    
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
    
    open func update(_ model: Any?) {
        self.signalBlock?()
    }
    
    // MARK: publics
    
    public func notification(identifier: String, userInfo: Any? = nil) {
        notificationBlock?(self, identifier, userInfo)
    }
}
