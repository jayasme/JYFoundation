//
//  JYConfigManager.swift
//  JYFoundation
//
//  Created by 荣超 on 2022/3/21.
//  Copyright © 2022 jayasme. All rights reserved.
//

import Foundation

public class JYConfigManager<T: JYConfig> {
    
    public private(set) var config: T
    public private(set) var path: URL
    public var autoSave: Bool {
        didSet {
            try? self.saveIfNeeded()
        }
    }
    
    public init(path: URL, defaultConfig: T, autoSave: Bool) {
        self.path = path
        self.autoSave = autoSave
        guard let data = try? Data(contentsOf: path),
              let config = T.deserialize(data: data) as? T
        else {
            self.config = defaultConfig
            try? self.saveIfNeeded()
            return
        }
        self.config = config
        self.config.changePropertyBlock = self.changeProperty
    }
    
    public func saveIfNeeded() throws {
        self.config.changePropertyBlock = self.changeProperty
        guard autoSave else {
            return
        }
        try self.save()
    }
    
    public func save() throws {
        do {
            guard let data = T.serialize(config: self.config) else {
                return
            }
            try data.write(to: self.path, options: .atomic)
        } catch {
            throw error
        }
    }
    
    // notification
    private func changeProperty() {
        self.notifications.forEach({ (key: String, value: ChangeNotification) in
            _ = value.target?.perform(value.selector, with: nil)
        })
        try? self.saveIfNeeded()
    }
    
    private var notifications: [String: ChangeNotification] = [:]
    
    public func addNotification(name: String, target: AnyObject?, selector: Selector) {
        let notification = ChangeNotification(target: target, selector: selector)
        notifications[name] = notification
    }
    
    public func removeNotification(name: String) {
        notifications.removeValue(forKey: name)
    }
}

extension JYConfigManager {
    
    private class ChangeNotification {
        weak var target: AnyObject?
        var selector: Selector

        init(target: AnyObject?, selector: Selector) {
            self.target = target
            self.selector = selector
        }
    }
}

open class JYConfig {
    
    internal var changePropertyBlock: (() -> Void)? = nil
    
    public func changeProperty() {
        self.changePropertyBlock?()
    }
    
    open class func serialize(config: JYConfig) -> Data? {
        fatalError("need to be implemented")
    }
    
    open class func deserialize(data: Data) -> JYConfig? {
        fatalError("need to be implemented")
    }
}
