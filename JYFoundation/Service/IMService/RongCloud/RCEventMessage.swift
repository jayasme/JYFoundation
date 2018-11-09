//
//  RCEventMessage.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/5/17.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation

class RCEventMessage: RCMessageContent {
    
    var content: String = ""
    var payload: [String: Any]?
    
    override init() {
        content = ""
        payload = nil
        super.init()
    }

    init(content: String, payload: [String: Any]?) {
        self.content = content
        self.payload = payload
        super.init()
    }
    
    override func encode() -> Data! {
        var dict = ["content": String(self.content)]
        if let payload = self.payload, let data = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted) {
            dict["payload"] = String(data: data, encoding: .utf8)
        }
        if let userInfo = self.senderUserInfo {
            dict["senderUserId"] = userInfo.userId
            dict["senderUserName"] = userInfo.name
            dict["senderUserAvatar"] = userInfo.portraitUri
        }
        return try! JSONSerialization.data(withJSONObject: dict, options: .init(rawValue: 0))
    }
    
    override func decode(with data: Data!) {
        if let dict = try? JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0)) as? [String: String] {
            self.content = dict!["content"]!
            if let string = dict?["payload"], let data = string.data(using: .utf8) {
                self.payload = (try? JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0))) as? [String: Any]
            }
            if let senderUserId = dict?["senderUserId"] {
                let name = (dict?["senderUserName"]) ?? ""
                let avatar = (dict?["senderUserAvatar"]) ?? ""
                self.senderUserInfo = RCUserInfo(userId: senderUserId, name: name, portrait: avatar)
            }
        }
    }
    
override static func persistentFlag() -> RCMessagePersistent {
        return RCMessagePersistent.MessagePersistent_STATUS
    }
    
    override static func getObjectName() -> String {
        return "RC:JYEvt"
    }
}
