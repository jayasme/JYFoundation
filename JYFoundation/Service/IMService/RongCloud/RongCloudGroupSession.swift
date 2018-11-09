//
//  RongCloudGroupSession.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/5/26.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import PromiseKit
import UserNotifications

/// Additional classes

fileprivate class RongCloudGroupUserListParameter : JYHttpParameter {
    var groupId: String
    
    required init(groupId: String) {
        self.groupId = groupId
        super.init()
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
}

class RongCloudGroupUserListModelUser : JYHttpModel {
    var id: String!
    var time: Date!
}

class RongCloudGroupUserListModel : JYHttpModel {
    var code: Int!
    var total: Int!
    var users: [RongCloudGroupUserListModelUser]!
}

/// The session

public class RongCloudGroupSession: JYIMSessionBase {
    public var id: String {
        return group.groupId
    }
    
    private(set) public var group: JYIMGroup
    
    private(set) public var service: JYIMServiceBase
    
    private(set) public var messages: [JYIMMessageBase] = []
    
    private(set) public var fetchingExhausted: Bool = false
    
    public weak var pushNotificationProviderDataSource: JYIMPushNotificationProviderDataSource? = nil
    
    public var userInfo: [String: Any]? = nil
    
    public var muted: Bool = false {
        didSet {
            client.setConversationNotificationStatus(.ConversationType_GROUP, targetId: id, isBlocked: muted, success: nil, error: nil)
        }
    }
    
    private var client: RCIMClient {
        get {
            return (service as! RongCloudService).client
        }
    }
    
    public init(service: RongCloudService, group: JYIMGroup, fetchHistory: Bool) {
        self.service = service
        self.group = group
        
        // fetch very last messages
        if fetchHistory {
            self.messages = fetchMessages()
        }
        
        // fetch muted
        client.getConversationNotificationStatus(.ConversationType_GROUP, targetId: id, success: { (status) in
            self.muted = status.rawValue == 0
        }, error: nil)
    }
    
    public func updateGroup(group: JYIMGroup) {
        self.group = group
    }
    
    public var unreadMessageCount: Int {
        get {
            return Int(client.getUnreadCount(.ConversationType_GROUP, targetId: id))
        }
    }
    
    public var lastMessage: JYIMMessageBase? {
        get {
            return messages.last
        }
    }
    
    public func messageBeforeMessage(message: JYIMMessageBase) -> JYIMMessageBase? {
        let index = messages.index(where: { $0.messageId == message.messageId })
        if index != nil && index! > 0 {
            return messages[index! - 1]
        } else {
            return nil
        }
    }
    
    public var draft: String? {
        get {
            return client.getTextMessageDraft(.ConversationType_GROUP, targetId: id)
        } set (value) {
            if let text = value?.on_blankToNil() {
                client.saveTextMessageDraft(.ConversationType_GROUP, targetId: id, content: text)
            } else {
                client.clearTextMessageDraft(.ConversationType_GROUP, targetId: id)
            }
        }
    }
    
    public func fetchMessages(pageSize: Int = 20) -> [JYIMMessageBase] {
        var rcMessages: [RCMessage] = []
        
        // because of messages are reversed, so must use the first message id
        if let lastMessageId = messages.first?.messageId {
            // fetch historical messages
            rcMessages = (client.getHistoryMessages(.ConversationType_GROUP, targetId: id, oldestMessageId: lastMessageId, count: Int32(pageSize)) as? [RCMessage] ?? []).reversed()
        } else {
            // fetch latest messages
            rcMessages = (client.getLatestMessages(.ConversationType_GROUP, targetId: id, count: Int32(pageSize)) as? [RCMessage] ?? []).reversed()
        }
        
        let msgs = rcMessages.compactMap({ (rcMessage) -> JYIMMessageBase? in
            if rcMessage.content is RCTextMessage {
                return RongCloudTextMessage(message: rcMessage)
            } else if rcMessage.content is RCImageMessage {
                return RongCloudImageMessage(message: rcMessage)
            } else if rcMessage.content is RCVoiceMessage {
                return RongCloudAudioMessage(message: rcMessage)
            } else {
                return nil
            }
        })
        messages = msgs + messages
        fetchingExhausted = rcMessages.count < pageSize
        
        return msgs
    }
    
    public func removeAllMessages() {
        messages.removeAll()
        fetchingExhausted = false
    }
    
    public func removeMessage(message: JYIMMessageBase) {
        guard let index = messages.index(where: { (m) -> Bool in
            return m.messageId == message.messageId
        }) else {
            return
        }
        
        messages.remove(at: index)
    }
    
    public func clearUnreadCount() {
        client.clearMessagesUnreadStatus(.ConversationType_GROUP, targetId: id)
    }
    
    public func readMessage(message : JYIMMessageBase) {
        client.setMessageReceivedStatus(message.messageId, receivedStatus: .ReceivedStatus_READ)
    }
    
    public func fetchUserList() -> Promise<[JYIMUser]> {
        guard let service = self.service as? RongCloudService else {
            return Promise.init(error: JYError())
        }
        
        let nonce = UUID().uuidString
        let timestamp = String(Int(Date.now().timeIntervalSince1970))
        let signature = (service.appSecret + nonce + timestamp).on_sha1()
        
        let url = "https://api.cn.ronghub.com/group/user/query.json"
        let parameters = RongCloudGroupUserListParameter(groupId: id)
        let headers: [String: String] = ["App-Key": service.appKey,
                                         "Nonce": nonce,
                                         "Timestamp": timestamp,
                                         "Signature": signature]
        
        return service.httpClient.fetchObject(url, method: .post, header: headers, parameter: parameters, type: RongCloudGroupUserListModel.self)
        .then {[weak self] data -> Promise<[JYIMUser]> in
            guard let service = self?.service as? RongCloudService, let dataProvider = service.dataProviderDelegate else {
                throw JYError()
            }
            
            let ids = data.users.map { $0.id! }
            return dataProvider.users(with: ids)
        }
    }
    
    public func sendMessage(text : String) -> Promise<JYIMTextMessageBase> {
        return service.user
        .then {user -> Promise<JYIMTextMessageBase> in
            guard let user = user else {
                throw JYError("Illigal logged user.")
            }
            
            return Promise<JYIMTextMessageBase> {[weak self] seal in
                guard let strongSelf = self else {
                    return
                }
                
                guard let message = RCTextMessage(content: text) else {
                    return
                }
                
                let pushContent = strongSelf.pushNotificationProviderDataSource?.pushContentText(session: strongSelf, user: user, text: text)
                let pushData = strongSelf.pushNotificationProviderDataSource?.pushDataText(session: strongSelf, user: user, text: text)
                message.senderUserInfo = RCUserInfo(userId: user.userId, name: user.name, portrait: user.avatar)
                _ = strongSelf.client.sendMessage(
                    .ConversationType_GROUP,
                    targetId: strongSelf.id,
                    content: message,
                    pushContent: pushContent,
                    pushData: pushData?.jy_toJsonString(),
                    success: { (messageId) in
                        let rcMessage = RCMessage(type: .ConversationType_GROUP,
                                                  targetId: strongSelf.id,
                                                  direction: .MessageDirection_SEND,
                                                  messageId: messageId,
                                                  content: message)
                        rcMessage!.sentTime = Int64(Date.now().timeIntervalSince1970 * 1000)
                        let msg = RongCloudTextMessage(message: rcMessage!)
                        strongSelf.messages.append(msg)
                        seal.fulfill(msg)
                    },
                    error: { (errCode, messageId) in
                        let msg = RongCloudTextMessage(messageId: messageId,
                                                        type: RCConversationType.ConversationType_GROUP,
                                                        targetId: strongSelf.id,
                                                        content: message)
                        seal.reject(JYError("Send message failed.", userInfo: [
                            "code": errCode.rawValue,
                            "message": msg] as [String: Any?]?))
                    }
                )
            }
        }
    }
    
    public func sendMessage(image : UIImage) -> Promise<JYIMImageMessageBase> {
        return service.user
        .then {user -> Promise<JYIMImageMessageBase> in
            guard let user = user else {
                throw JYError("Illigal logged user.")
            }
            
            return Promise<JYIMImageMessageBase> {[weak self] seal in
                guard let strongSelf = self else {
                    return
                }
                
                guard let message = RCImageMessage(image: image) else {
                    return
                }
                
                let pushContent = strongSelf.pushNotificationProviderDataSource?.pushContentImage(session: strongSelf, user: user, image: image)
                let pushData = strongSelf.pushNotificationProviderDataSource?.pushDataImage(session: strongSelf, user: user, image: image)
                message.senderUserInfo = RCUserInfo(userId: user.userId, name: user.name, portrait: user.avatar)
                _ = strongSelf.client.sendMediaMessage(
                    .ConversationType_GROUP,
                    targetId: strongSelf.id,
                    content: message,
                    pushContent: pushContent,
                    pushData: pushData?.jy_toJsonString(),
                    progress: nil,
                    success: { (messageId) in
                        let rcMessage = RCMessage(type: .ConversationType_GROUP,
                                                  targetId: strongSelf.id,
                                                  direction: .MessageDirection_SEND,
                                                  messageId: messageId,
                                                  content: message)
                        rcMessage!.sentTime = Int64(Date.now().timeIntervalSince1970 * 1000)
                        let msg = RongCloudImageMessage(message: rcMessage!)
                        strongSelf.messages.append(msg)
                        seal.fulfill(msg)
                    },
                    error: { (errCode, messageId) in
                        let msg = RongCloudImageMessage(messageId: messageId,
                                                        type: RCConversationType.ConversationType_GROUP,
                                                        targetId: strongSelf.id,
                                                        content: message)
                        seal.reject(JYError("Send message failed.", userInfo: [
                            "code": errCode.rawValue,
                            "message": msg] as [String: Any?]?))
                    },
                    cancel: { _ in }
                )
            }
        }
    }
    
    public func sendMessage(audio : Data, duration : TimeInterval) -> Promise<JYIMAudioMessageBase> {
        return service.user
        .then {user -> Promise<JYIMAudioMessageBase> in
            guard let user = user else {
                throw JYError("Illigal logged user.")
            }
        
            return Promise<JYIMAudioMessageBase> {[weak self] seal in
                guard let strongSelf = self else {
                    return
                }
                
                guard let message = RCVoiceMessage(audio: audio, duration: Int(duration)) else {
                    return
                }
                
                let pushContent = strongSelf.pushNotificationProviderDataSource?.pushContentAudio(session: strongSelf, user: user, audio: audio, duration: duration)
                let pushData = strongSelf.pushNotificationProviderDataSource?.pushDataAudio(session: strongSelf, user: user, audio: audio, duration: duration)
                message.senderUserInfo = RCUserInfo(userId: user.userId, name: user.name, portrait: user.avatar)
                _ = strongSelf.client.sendMessage(
                    .ConversationType_GROUP,
                    targetId: strongSelf.id,
                    content: message,
                    pushContent: pushContent,
                    pushData: pushData?.jy_toJsonString(),
                    success: { (messageId) in
                        let rcMessage = RCMessage(type: .ConversationType_GROUP,
                                                  targetId: strongSelf.id,
                                                  direction: .MessageDirection_SEND,
                                                  messageId: messageId,
                                                  content: message)
                        rcMessage!.sentTime = Int64(Date.now().timeIntervalSince1970 * 1000)
                        let msg = RongCloudAudioMessage(message: rcMessage!)
                        strongSelf.messages.append(msg)
                        seal.fulfill(msg)
                    },
                    error: { (errCode, messageId) in
                        let msg = RongCloudAudioMessage(messageId: messageId,
                                                        type: RCConversationType.ConversationType_GROUP,
                                                        targetId: strongSelf.id,
                                                        content: message)
                        seal.reject(JYError("Send message failed.", userInfo: [
                            "code": errCode.rawValue,
                            "message": msg] as [String: Any?]?))
                    }
                )
            }
        }
    }
    
    
    public func sendEvent(content: String, payload: [String: Any]?) -> Promise<JYIMEventMessageBase> {
        return service.user
        .then {user -> Promise<JYIMEventMessageBase> in
            guard let user = user else {
                throw JYError("Illigal logged user.")
            }
            
            return Promise<JYIMEventMessageBase> {[weak self] seal in
                guard let strongSelf = self else {
                    return
                }
                
                let message = RCEventMessage(content: content, payload: payload)
                
                let pushContent = strongSelf.pushNotificationProviderDataSource?.pushContentEvent(session: strongSelf, user: user, content: content, payload: payload)
                let pushData = strongSelf.pushNotificationProviderDataSource?.pushDataEvent(session: strongSelf, user: user, content: content, payload: payload)
                message.senderUserInfo = RCUserInfo(userId: user.userId, name: user.name, portrait: user.avatar)
                _ = strongSelf.client.sendMessage(
                    .ConversationType_GROUP,
                    targetId: strongSelf.id,
                    content: message,
                    pushContent: pushContent,
                    pushData: pushData?.jy_toJsonString(),
                    success: { (messageId) in
                        let rcMessage = RCMessage(type: RCConversationType.ConversationType_GROUP,
                                                  targetId: strongSelf.id,
                                                  direction: .MessageDirection_SEND,
                                                  messageId: messageId,
                                                  content: message)
                        rcMessage!.sentTime = Int64(Date.now().timeIntervalSince1970 * 1000)
                        let msg = RongCloudEventMessage(message: rcMessage!)
                        strongSelf.messages.append(msg)
                        seal.fulfill(msg)
                    },
                    error: { (errCode, messageId) in
                        let msg = RongCloudEventMessage(messageId: messageId,
                                                        type: RCConversationType.ConversationType_GROUP,
                                                        targetId: strongSelf.id,
                                                        content: message)
                        seal.reject(JYError("Send message failed.", userInfo: [
                            "code": errCode.rawValue,
                            "message": msg] as [String: Any?]?))
                    }
                )
            }
        }
    }
    
    public func sendToTop() {
        client.setConversationToTop(.ConversationType_GROUP, targetId: id, isTop: true)
    }
    
    public func leave() {
        self.service.removeSession(session: self)
    }
    
    // MARK: Receiving messages
    public func receiveMessage(message: JYIMMessageBase) {
        // 获取 UserModel
        guard let delegate = service.dataProviderDelegate else {
            return
        }
        
        _ = delegate.user(with: message.senderId)
        .done {[weak self] user in
            guard let strongSelf = self else {
                return
            }
                
            if (!strongSelf.messages.contains(where: { (m) -> Bool in
                return m.messageId == message.messageId
            })) {
                strongSelf.messages.append(message)
            }
            
            // 发送通知
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name.IM.JYIMMessageReceived,
                    object: nil,
                    userInfo: ["message": message, "session": strongSelf]
                )
                
                // 发送推送
                if (!strongSelf.muted) {
                    let content = UNMutableNotificationContent()
                    var pushContent: String?
                    var pushData: [String: Any]?
                    if let msg = message as? JYIMTextMessageBase, let text = msg.content {
                        pushContent = strongSelf.pushNotificationProviderDataSource?.pushContentText(session: strongSelf, user: user, text: text)
                        pushData = strongSelf.pushNotificationProviderDataSource?.pushDataText(session: strongSelf, user: user, text: text)
                    } else if let msg = message as? JYIMImageMessageBase, let image = msg.thumbnailImage {
                        pushContent = strongSelf.pushNotificationProviderDataSource?.pushContentImage(session: strongSelf, user: user, image: image)
                        pushData = strongSelf.pushNotificationProviderDataSource?.pushDataImage(session: strongSelf, user: user, image: image)
                    } else if let msg = message as? JYIMAudioMessageBase, let audio = msg.content {
                        pushContent = strongSelf.pushNotificationProviderDataSource?.pushContentAudio(session: strongSelf, user: user, audio: audio, duration: msg.duration)
                        pushData = strongSelf.pushNotificationProviderDataSource?.pushDataAudio(session: strongSelf, user: user, audio: audio, duration: msg.duration)
                    } else if let msg = message as? JYIMEventMessageBase, let payload = msg.payload  {
                        pushContent = strongSelf.pushNotificationProviderDataSource?.pushContentEvent(session: strongSelf, user: user, content: msg.content, payload: payload)
                        pushData = strongSelf.pushNotificationProviderDataSource?.pushDataEvent(session: strongSelf, user: user, content: msg.content, payload: payload)
                    }
                    
                    guard let strongPushContent = pushContent else {
                        return
                    }
                    
                    content.body = strongPushContent
                    content.userInfo = pushData ?? [:]
                    content.badge = strongSelf.service.unreadMessageCount as NSNumber
                    content.sound = UNNotificationSound(named: "default")
                    let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 0.1, repeats: false)
                    let identifier = String(format: "%d", message.messageId)
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                }
            }
        }
    }
}
