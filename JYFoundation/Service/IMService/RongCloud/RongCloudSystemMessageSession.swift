//
//  RongCloudSystemMessageSession.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/7/5.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import PromiseKit
import UserNotifications

public class RongCloudSystemMessageSession: JYIMSessionBase {
    
    public var id: String
    
    public var draft: String? = nil
    
    private(set) public var service: JYIMServiceBase
    
    private(set) public var messages: [JYIMMessageBase] = []
    
    private(set) public var fetchingExhausted: Bool = false
    
    public var userInfo: [String: Any]? = nil
    
    public weak var pushNotificationProviderDataSource: JYIMPushNotificationProviderDataSource? = nil
    
    private var client: RCIMClient {
        get {
            return (service as! RongCloudService).client
        }
    }
    
    public init(service: RongCloudService, id: String, fetchHistory: Bool) {
        self.service = service
        self.id = id
        
        // fetch very last messages
        if fetchHistory {
            self.messages = fetchMessages()
        }
    }
    
    public var unreadMessageCount: Int {
        get {
            return Int(client.getUnreadCount(.ConversationType_SYSTEM, targetId: id))
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
    
    public func fetchMessages(pageSize: Int = 20) -> [JYIMMessageBase] {
        var rcMessages: [RCMessage] = []
        
        // because of messages are reversed, so must use the first message id
        if let lastMessageId = messages.first?.messageId {
            // fetch historical messages
            rcMessages = (client.getHistoryMessages(.ConversationType_SYSTEM, targetId: id, oldestMessageId: lastMessageId, count: Int32(pageSize)) as? [RCMessage] ?? []).reversed()
        } else {
            // fetch latest messages
            rcMessages = (client.getLatestMessages(.ConversationType_SYSTEM, targetId: id, count: Int32(pageSize)) as? [RCMessage] ?? []).reversed()
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
        client.clearMessagesUnreadStatus(.ConversationType_SYSTEM, targetId: id)
        
        // notify
        //service.notifyService?.newIMCount = service._sessions.unreadMessageCount
        //service.self.notifyService?.performIMCountRefresh()
    }
    
    public func readMessage(message : JYIMMessageBase) {
        client.setMessageReceivedStatus(message.messageId, receivedStatus: .ReceivedStatus_READ)
    }
    
    
    // do nothing
    
    public func sendMessage(text: String) -> Promise<JYIMTextMessageBase> {
        fatalError()
    }
    
    public func sendMessage(image: UIImage) -> Promise<JYIMImageMessageBase> {
        fatalError()
    }
    
    public func sendMessage(audio: Data, duration: TimeInterval) -> Promise<JYIMAudioMessageBase> {
        fatalError()
    }
    
    public func sendEvent(content: String, payload: [String : Any]?) -> Promise<JYIMEventMessageBase> {
        fatalError()
    }
    
    
    
    
    public func sendToTop() {
        client.setConversationToTop(.ConversationType_SYSTEM, targetId: id, isTop: true)
    }
    
    // MARK: Receiving messages
    public func receiveMessage(message: JYIMMessageBase) {
        // 获取 UserModel
        if (!messages.contains(where: { (m) -> Bool in
            return m.messageId == message.messageId
        })) {
            messages.append(message)
        }
        
        // 发送通知
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name.IM.JYIMMessageReceived,
                object: nil,
                userInfo: ["message": message, "session": self]
            )
        }
        
        let systemUser = JYIMUser(userId: "0", name: "系统消息", avatar: nil)
        
        // 发送推送
        let content = UNMutableNotificationContent()
        var pushContent: String?
        var pushData: [String: Any]?
        if let msg = message as? JYIMTextMessageBase, let text = msg.content {
            pushContent = pushNotificationProviderDataSource?.pushContentText(session: self, user: systemUser, text: text)
            pushData = pushNotificationProviderDataSource?.pushDataText(session: self, user: systemUser, text: text)
        } else if let msg = message as? JYIMImageMessageBase, let image = msg.thumbnailImage {
            pushContent = pushNotificationProviderDataSource?.pushContentImage(session: self, user: systemUser, image: image)
            pushData = pushNotificationProviderDataSource?.pushDataImage(session: self, user: systemUser, image: image)
        } else if let msg = message as? JYIMAudioMessageBase, let audio = msg.content {
            pushContent = pushNotificationProviderDataSource?.pushContentAudio(session: self, user: systemUser, audio: audio, duration: msg.duration)
            pushData = pushNotificationProviderDataSource?.pushDataAudio(session: self, user: systemUser, audio: audio, duration: msg.duration)
        } else if let msg = message as? JYIMEventMessageBase, let payload = msg.payload  {
            pushContent = pushNotificationProviderDataSource?.pushContentEvent(session: self, user: systemUser, content: msg.content, payload: payload)
            pushData = pushNotificationProviderDataSource?.pushDataEvent(session: self, user: systemUser, content: msg.content, payload: payload)
        }
        
        guard let strongPushContent = pushContent else {
            return
        }
        
        content.body = strongPushContent
        content.userInfo = pushData ?? [:]
        content.badge = service.unreadMessageCount as NSNumber
        content.sound = UNNotificationSound(named: "default")
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 0.1, repeats: false)
        let identifier = String(format: "%d", message.messageId)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
