//
//  RongCloudMessage.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/19.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation


public class RongCloudMessage: JYIMMessageBase {
    
    fileprivate var message: RCMessage
    
    public convenience init(messageId: Int, type: RCConversationType, targetId: String, content: RCMessageContent) {
        let message = RCMessage(type: type,
                                targetId: targetId,
                                direction: .MessageDirection_SEND,
                                messageId: messageId,
                                content: content)
        message!.sentTime = Int64(Date.now().timeIntervalSince1970 * 1000)
        self.init(message: message!)
    }
    
    public init(message : RCMessage) {
        self.message = message
    }

    public var messageId: Int {
        return message.messageId
    }
    
    public var sentTime: Date {
        return Date(timeIntervalSince1970: TimeInterval(message.sentTime / 1000))
    }
    
    public var receivedTime: Date {
        return Date(timeIntervalSince1970: TimeInterval(message.receivedTime / 1000))
    }
    
    public var shownTime: Date {
        return direction == .send ? sentTime : receivedTime
    }

    public var direction: JYIMMessageDirection {
        switch(message.messageDirection) {
        case .MessageDirection_SEND:
            return .send
        case .MessageDirection_RECEIVE:
            return .receive
        }
    }
    public var status : JYIMMessageStatus {
        switch(direction) {
        case .send:
            switch(message.sentStatus) {
            case .SentStatus_SENDING:
                return .sending
            case .SentStatus_RECEIVED:
                fallthrough
            case .SentStatus_SENT:
                return .sent
            case .SentStatus_FAILED:
                return .failed
            case .SentStatus_READ:
                return .read
            default:
                return .unknown
            }
        case .receive:
            switch(message.receivedStatus) {
            case .ReceivedStatus_MULTIPLERECEIVE:
                fallthrough
            case .ReceivedStatus_UNREAD:
                fallthrough
            case .ReceivedStatus_RETRIEVED:
                return .sent
            case .ReceivedStatus_DOWNLOADED:
                fallthrough
            case .ReceivedStatus_LISTENED:
                return .received
            case .ReceivedStatus_READ:
                return .read
            }
        }
    }
    
    public var type: JYIMMessageType {
        return .unknown
    }
    
    public var rawContent: String {
        return ""
    }
    
    public var sender: JYIMUser? {
        guard let user = message.content.senderUserInfo else {
            return nil
        }
        
        return JYIMUser(userId: user.userId, name: user.name, avatar: user.portraitUri)
    }
    
    public var senderId: String {
        return message.senderUserId
    }
}


public class RongCloudTextMessage: RongCloudMessage, JYIMTextMessageBase {
    
    public var content: String? {
        return (message.content as? RCTextMessage)?.content
    }
    
    public override var type: JYIMMessageType {
        return .text
    }
    
    public override var rawContent: String {
        return content ?? ""
    }
}

public class RongCloudImageMessage: RongCloudMessage, JYIMImageMessageBase {
    
    public var thumbnailImage: UIImage? {
        return (message.content as? RCImageMessage)?.thumbnailImage
    }
    
    public var imageUrl: String? {
        return (message.content as? RCImageMessage)?.imageUrl
    }
    
    public override var type: JYIMMessageType {
        return .image
    }
    
    public override var rawContent: String {
        return "[图片]"
    }
}


public class RongCloudAudioMessage: RongCloudMessage, JYIMAudioMessageBase {
    
    public var content: Data? {
        return (message.content as? RCVoiceMessage)?.wavAudioData
    }
    
    public var duration: TimeInterval {
        guard let duration = (message.content as? RCVoiceMessage)?.duration else {
            return 0
        }
        return TimeInterval(duration)
    }
    
    public override var type: JYIMMessageType {
        return .audio
    }
    
    public override var rawContent: String {
        return "[语音]"
    }
}

public class RongCloudEventMessage: RongCloudMessage, JYIMEventMessageBase {
    
    public var content: String {
        return (message.content as? RCEventMessage)?.content ?? ""
    }
    
    public var payload: [String: Any]? {
        return (message.content as? RCEventMessage)?.payload
    }
    
    public override var type: JYIMMessageType {
        return .event
    }
    
    public override var rawContent: String {
        return content
    }
}
