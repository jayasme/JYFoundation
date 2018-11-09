//
//  IIMService.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/20.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import PromiseKit

public protocol JYIMServiceBase: class {
    
    var status : JYIMServiceStatus { get }
    var sessions: [JYIMSessionBase] { get }
    var unreadMessageCount: Int { get }
    var dataProviderDelegate: JYIMDataProviderDelegate? { get set }
    var userId: String? { get }
    var user: Promise<JYIMUser?> { get }
    
    func setup(appKey: String, appSecret: String)
    
    func connect(userId: String)
        
    func disconnect()
    
    func syncSessions() -> Promise<Void>
    
    func getPrivateSession(withUserId userId: String, fetchHistory: Bool) -> Promise<RongCloudPrivateSession>
    
    func getPrivateSession(withUser user: JYIMUser, fetchHistory: Bool) -> RongCloudPrivateSession
    
    func getGroupSession(withGroupId groupId: String, fetchHistory: Bool) -> Promise<RongCloudGroupSession>

    func getGroupSession(withGroup group: JYIMGroup, fetchHistory: Bool) -> RongCloudGroupSession
    
    func getSystemMessageSession(id: String, fetchHistory: Bool) -> RongCloudSystemMessageSession
    
    func getExistingSystemMessageSession() -> RongCloudSystemMessageSession?
    
    func joinChatRoom(withChatRoom chatRoom: JYIMChatRoom, fetchHistory: Bool) -> Promise<RongCloudChatRoomSession?>

    func removeSession(session : JYIMSessionBase)
    
    func isUserBlocked(userId: String) -> Promise<Bool>
    
    func blockUser(userId : String) -> Promise<Void>
    
    func unblockUser(userId : String)
}


public protocol JYIMSessionBase: class {
    var id: String { get }
    var service: JYIMServiceBase { get }
    var messages: [JYIMMessageBase] { get }
    var unreadMessageCount: Int { get }
    var lastMessage: JYIMMessageBase? { get }
    var draft: String? { get set }
    var fetchingExhausted: Bool { get }
    var pushNotificationProviderDataSource: JYIMPushNotificationProviderDataSource? { get set }
    var userInfo: [String: Any]? { get set }
    
    @discardableResult
    func fetchMessages(pageSize: Int) -> [JYIMMessageBase]
    
    func messageBeforeMessage(message: JYIMMessageBase) -> JYIMMessageBase?
    
    func removeMessage(message: JYIMMessageBase)
    
    func removeAllMessages()
    
    func clearUnreadCount()
    
    func readMessage(message : JYIMMessageBase)
    
    func sendMessage(text : String) -> Promise<JYIMTextMessageBase>
    
    func sendMessage(image : UIImage) -> Promise<JYIMImageMessageBase>
    
    func sendMessage(audio : Data, duration : TimeInterval) -> Promise<JYIMAudioMessageBase>
    
    func sendEvent(content: String, payload: [String: Any]?) -> Promise<JYIMEventMessageBase>
    
    func sendToTop()
    
    func receiveMessage(message: JYIMMessageBase)
}


public protocol JYIMMessageBase: class {
    var messageId: Int { get }
    var sentTime: Date { get }
    var receivedTime: Date { get }
    var shownTime: Date { get }
    var direction: JYIMMessageDirection { get }
    var status : JYIMMessageStatus { get }
    var type: JYIMMessageType { get }
    var rawContent: String { get }
    var senderId: String { get }
    var sender: JYIMUser? { get }
}

public protocol JYIMTextMessageBase: JYIMMessageBase {
    var content: String? { get }
}

public protocol JYIMImageMessageBase: JYIMMessageBase {
    var thumbnailImage: UIImage? { get }
    var imageUrl: String? { get }
}

public protocol JYIMAudioMessageBase: JYIMMessageBase {
    var content: Data? { get }
    var duration: TimeInterval { get }
}

public protocol JYIMEventMessageBase: JYIMMessageBase {
    var content: String { get }
    var payload: [String: Any]? { get }
}

extension NSNotification.Name {
    public struct IM {
        public static let JYIMStatusChanged: NSNotification.Name =
            NSNotification.Name(rawValue: "JYIMStatusChanged")
        
        public static let JYIMMessageReceived: NSNotification.Name =
            NSNotification.Name(rawValue: "JYIMGlobalMessageReceived")
        
        public static let JYIMMessageRefreshList: NSNotification.Name =
            NSNotification.Name(rawValue: "JYIMMessageRefreshList")
    }
}
