//
//  JYConfigManager.swift
//  JYFoundation
//
//  Created by 荣超 on 2022/3/21.
//  Copyright © 2022 jayasme. All rights reserved.
//

import Foundation

extension Notification.Name {
    
    public static let JYConfigChanged = Notification.Name("JYConfigChanged")
}

public class JYConfigManager<T: JYConfig> {
    
    public private(set) var config: T
    public private(set) var path: URL
    public var autoSave: Bool {
        didSet {
            try? self.saveIfNeeded()
        }
    }
    
    public init(path: URL, autoSave: Bool) {
        self.path = path
        self.autoSave = autoSave
        guard let data = try? Data(contentsOf: path),
              let configItems = try! JSONSerialization.jsonObject(with: data) as? JYConfig.ConfigItems
        else {
            self.config = T()
            self.config.notifyChange = self.notifyConfigChange
            return
        }
        self.config = T(items: configItems)
        self.config.notifyChange = self.notifyConfigChange
    }
    
    public func saveIfNeeded() throws {
        guard autoSave else {
            return
        }
        try self.save()
    }
    
    public func save() throws {
        do {
            guard let data = try? JSONSerialization.data(withJSONObject: self.config.configItems) else {
                return
            }
            try data.write(to: self.path, options: [.atomic])
        } catch {
            throw error
        }
    }
    
    // notification
    private func notifyConfigChange() {
        NotificationCenter.default.post(
            name: Notification.Name.JYConfigChanged,
            object: nil,
            userInfo: ["config": self.config]
        )
        try? self.saveIfNeeded()
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
    
    public typealias ConfigItems = [String: Any]
    
    fileprivate var notifyChange: (() -> Void)? = nil
    fileprivate var configItems: ConfigItems {
        didSet {
            self.notifyChange?()
        }
    }
    
    required public init(items: ConfigItems = [:]) {
        self.configItems = items
    }
    
    public func setValue(for key: String, value: (any Codable)?) throws {
        self.configItems[key] = value
    }
    
    public func getValue(for key: String) -> Any? {
        guard self.configItems.keys.contains(where: { $0 == key }) else {
            return nil
        }
        return self.configItems[key]
    }
    
    public func removeItem(by key: String) {
        self.configItems.removeValue(forKey: key)
    }
}
