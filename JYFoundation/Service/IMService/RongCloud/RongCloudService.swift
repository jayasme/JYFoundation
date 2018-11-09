//
//  RongCloudService.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/18.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit
import PromiseKit
import HandyJSON
import UserNotifications

fileprivate class RongCloudToken: JYHttpModel {
    var code: Int!
    var userId: String!
    var token: String!
}

fileprivate class RongCloudUserTokenParameter : JYHttpParameter {
    var userId: String
    var name: String?
    var portraitUri: String?
    
    required init(userId: String, name: String? = nil, portraitUri: String? = nil) {
        self.userId = userId
        self.name = name
        self.portraitUri = portraitUri
        super.init()
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
}

public class RongCloudService: NSObject, JYIMServiceBase, RCIMClientReceiveMessageDelegate, RCConnectionStatusChangeDelegate {    
    
    private static let kRongCloudTokenKey = "__RongCloud_Token__"
    
    private(set) internal weak var client: RCIMClient!
    
    internal var httpClient: JYHttpClient = JYHttpClient.init(timeoutInterval: 10)
    
    internal var appKey: String = ""
    internal var appSecret: String = ""
    
    private(set) public var status : JYIMServiceStatus = .disconnected {
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name.IM.JYIMStatusChanged, object: nil, userInfo: ["status": status])
        }
    }
    
    private(set) public var sessions: [JYIMSessionBase]  = []
    
    public weak var dataProviderDelegate: JYIMDataProviderDelegate? = nil
    
    private(set) public var userId: String? = nil
    
    public var user: Promise<JYIMUser?> {
        guard let userId = self.userId, let delegate = self.dataProviderDelegate else {
            return Promise.value(nil)
        }
        
        return delegate.user(with: userId)
        .map{ user -> JYIMUser in
            return user
        }
    }
    
    public static var shared: RongCloudService = RongCloudService(client: RCIMClient.shared())

    // MARK: Initializer
    
    fileprivate init(client: RCIMClient) {
        self.client = client
        client.registerMessageType(RCEventMessage.self)
        status = .unknown
    }
    
    public func setup(appKey: String, appSecret: String) {
        self.appKey = appKey
        self.appSecret = appSecret
        client.initWithAppKey(appKey)
    }
    
    public func disconnect() {
        client.disconnect()
        self.userId = nil
        UserDefaults.standard.removeObject(forKey: RongCloudService.kRongCloudTokenKey);
        status = .disconnected
    }
    
    
    public func connect(userId: String) {
        guard status == .disconnected || status == .kicked || status == .unknown else {
            return
        }
        
        status = .connecting
        
        requestToken(userId: userId)
        .done {[weak self] token in
            self?.privateConnect(userId: userId, token: token)
        }.catch {[weak self] error in
            // retry
            print("[RongCloud] Get token error: " + error.localizedDescription)
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.connect(userId: userId)
        }
    }
    
    private func requestToken(userId: String) -> Promise<String> {
        guard let dataProviderDelegate = self.dataProviderDelegate else {
            return Promise<String>.init(error: JYError.init("dataProviderDelegate must be assigned before connect."))
        }
        
        if let token = UserDefaults.standard.value(forKey: RongCloudService.kRongCloudTokenKey) as? String {
            return Promise<String>.value(token)
        } else {
            
            return dataProviderDelegate.user(with: userId)
            .then {[weak self] user -> Promise<String> in
                guard let strongSelf = self else {
                    return Promise<String>.init(error: JYError.init("The service has been declloced"))
                }
                
                let nonce = UUID().uuidString
                let timestamp = String(Int(Date.now().timeIntervalSince1970))
                let signature = (strongSelf.appSecret + nonce + timestamp).on_sha1()
                
                let url = "https://api.cn.ronghub.com/user/getToken.json"
                let parameters = RongCloudUserTokenParameter(userId: user.userId, name: user.name, portraitUri: user.avatar)
                let headers: [String: String] = ["App-Key": strongSelf.appKey,
                                                 "Nonce": nonce,
                                                 "Timestamp": timestamp,
                                                 "Signature": signature]
                
                return strongSelf.httpClient.fetchObject(url, method: .post, header: headers, parameter: parameters, type: RongCloudToken.self)
                    .map { userToken -> String in
                        guard let token = userToken.token else {
                            throw JYError("[RongCloud] Get token from RongCloud server error.")
                        }
                        UserDefaults.standard.setValue(token, forKey: RongCloudService.kRongCloudTokenKey)
                        UserDefaults.standard.synchronize()
                        return token
                }
            }
        }
    }
    
    private func privateConnect(userId: String, token: String) {
        client.connect(
            withToken: token,
            success: {[weak self] info in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.client.setRCConnectionStatusChangeDelegate(strongSelf)
                strongSelf.client.setReceiveMessageDelegate(strongSelf, object: nil)
                strongSelf.status = .connected
                strongSelf.userId = userId
                _ = strongSelf.syncSessions()
        }, error: {errorCode in
            // 此处融云会自动连接，将userid设置下即可
            print("[RongCloud] Connect to RongCloud error, Rongcloud will reconnect automatically.")
            self.userId = userId
        }, tokenIncorrect: {[weak self] in
            // need renew the token
            guard let strongSelf = self else {
                return
            }
            UserDefaults.standard.removeObject(forKey: RongCloudService.kRongCloudTokenKey)
            strongSelf.status = .unknown
            strongSelf.connect(userId: userId)
        })
    }
    
    
    // MARK: Sessions
    
    public func syncSessions() -> Promise<Void> {
        return when(fulfilled: fetchGroupSessions(), fetchPrivateSessions())
        .done {[weak self] (groupSessions, privateSessions) in
            
            guard let strongSelf = self else {
                return
            }
            
            let chatRoomSessions: [JYIMSessionBase] = strongSelf.sessions.filter{ $0 is RongCloudChatRoomSession }
            
            let systemMessageSessions: [JYIMSessionBase] = strongSelf.fetchSystemMessageSessions()
                
            var newSessions: [JYIMSessionBase] = groupSessions?.filter{ $0.lastMessage != nil } ?? []
            if let privateSession = privateSessions {
                newSessions += privateSession as [JYIMSessionBase]
            }
            newSessions += chatRoomSessions
            newSessions += systemMessageSessions
            strongSelf.sessions = newSessions.sorted(by: { (session1, session2) -> Bool in
                let time1 = session1.lastMessage?.shownTime
                let time2 = session2.lastMessage?.shownTime
                    
                return (time1 != nil && time2 == nil) || (time1 != nil && time2 != nil && time1! > time2!)
            })
        }
    }
    
    private func fetchPrivateSessions() -> Promise<[RongCloudPrivateSession]?> {
        guard let delegate = self.dataProviderDelegate else {
            return Promise.value(nil)
        }
        
        let userIds: [String] = client.getConversationList([RCConversationType.ConversationType_PRIVATE.rawValue]).compactMap({ con -> String? in
            guard let conversation = con as? RCConversation, conversation.conversationType == .ConversationType_PRIVATE else {
                return nil
            }
            
            return conversation.targetId
        })
        
        guard userIds.count > 0 else {
            return Promise.value([])
        }
        
        return delegate.users(with: userIds)
        .map{ [weak self] users -> [RongCloudPrivateSession] in
            guard let strongSelf = self else {
                return []
            }
                
            return users.map{ strongSelf.getPrivateSession(withUser: $0) }
        }
    }
    
    private func fetchGroupSessions() -> Promise<[RongCloudGroupSession]?> {
        guard let delegate = self.dataProviderDelegate else {
            return Promise.value(nil)
        }
        
        return delegate.groups()
        .map{[weak self] groups -> [RongCloudGroupSession]? in
            guard let strongSelf = self else {
                return nil
            }
            
            return groups.map{ strongSelf.getGroupSession(withGroup: $0) }
        }
    }
    
    private func fetchSystemMessageSessions() -> [RongCloudSystemMessageSession] {
        let ids = client.getConversationList([RCConversationType.ConversationType_SYSTEM.rawValue]).compactMap({ con -> String? in
            guard let conversation = con as? RCConversation, conversation.conversationType == .ConversationType_SYSTEM else {
                return nil
            }
            
            return conversation.targetId
        })
        
        return ids.map{ self.getSystemMessageSession(id: $0) }
    }
    
    public var unreadMessageCount: Int {
        get {
            return sessions.on_reduce(body: { (session, count) -> Int in
                return session.unreadMessageCount + count
            }, initalValue: 0)
        }
    }
    
    
    
    // MARK: Common parts
    
    public func removeSession(session : JYIMSessionBase) {
        guard let index = self.sessions.index(where: { $0.id == session.id }) else {
            return
        }
        
        sessions.remove(at: index)
        
        var conversationType: RCConversationType? = nil
        if (session is RongCloudPrivateSession) {
            conversationType = .ConversationType_PRIVATE
        } else if (session is RongCloudGroupSession) {
            conversationType = .ConversationType_GROUP
        } else if (session is RongCloudChatRoomSession) {
            conversationType = .ConversationType_CHATROOM
        }
        
        if (conversationType != nil) {
            client.clearMessages(conversationType!, targetId: session.id)
            client.remove(conversationType!, targetId: session.id)
        }
    }
    
    // MARK: Private conversation
    public func getPrivateSession(withUserId userId: String, fetchHistory: Bool = true) -> Promise<RongCloudPrivateSession> {
        guard let delegate = dataProviderDelegate else {
            return Promise.init(error: JYError.init("dataProviderDelegate must be assigned before getPrivateSession."))
        }
        
        return delegate.user(with: userId)
        .map { [weak self] user -> RongCloudPrivateSession in
            guard let strongSelf = self else {
                throw JYError.init("service has been delloced.")
            }
                
            return strongSelf.getPrivateSession(withUser: user, fetchHistory: fetchHistory)
        }
    }
    
    public func getPrivateSession(withUser user: JYIMUser, fetchHistory: Bool = true) -> RongCloudPrivateSession {
        if let session = self.sessions.first(where: { (s) -> Bool in
            return s is RongCloudPrivateSession && s.id == user.userId
        }) as? RongCloudPrivateSession {
            session.user.name = session.user.name
            return session
        }
        
        let session = RongCloudPrivateSession(service: self, user: user, fetchHistory: fetchHistory)
        sessions.append(session)
        return session
    }
    
    // MARK: Group conversations
    public func getGroupSession(withGroupId groupId: String, fetchHistory: Bool = true) -> Promise<RongCloudGroupSession> {
        guard let delegate = dataProviderDelegate else {
            return Promise.init(error: JYError.init("dataProviderDelegate must be assigned before getGroupSession."))
        }
        
        return delegate.group(with: groupId)
        .map { [weak self] group -> RongCloudGroupSession in
            guard let strongSelf = self else {
                throw JYError.init("service has been delloced.")
            }
            
            return strongSelf.getGroupSession(withGroup: group, fetchHistory: fetchHistory)
        }
    }
    
    public func getGroupSession(withGroup group: JYIMGroup, fetchHistory: Bool = true) -> RongCloudGroupSession {
        if let session = self.sessions.first(where: { (s) -> Bool in
            return s is RongCloudGroupSession && s.id == group.groupId
        }) as? RongCloudGroupSession {
            session.group.name = group.name
            return session
        }
        
        let session = RongCloudGroupSession(service: self, group: group, fetchHistory: fetchHistory)
        sessions.append(session)
        return session
    }
    
    // MARK: Chatroom conversations
    
    public func joinChatRoom(withChatRoom chatRoom: JYIMChatRoom, fetchHistory: Bool = false) -> Promise<RongCloudChatRoomSession?> {
        return Promise<Void> { seal in
            client.joinChatRoom(chatRoom.chatRoomId, messageCount: 0, success: {
                print("Joined chat room '" + chatRoom.chatRoomId + "' successfully.")
                seal.fulfill(())
            }, error: { error in
                let err = ONError.error(code: .RongCloudCode, description: "Joining chat room error")
                seal.reject(err)
            })
        }.map {[weak self] _ -> RongCloudChatRoomSession? in
            guard let strongSelf = self else {
                return nil
            }
            if let session = strongSelf.sessions.first(where: { (s) -> Bool in
                guard let session = s as? RongCloudChatRoomSession else {
                    return false
                }
                return session.chatRoom == chatRoom
            }) as? RongCloudChatRoomSession {
                return session
            }
            
            let session = RongCloudChatRoomSession(service: strongSelf, chatRoom: chatRoom, fetchHistory: fetchHistory)
            _ = DispatchQueue.main.jy_delay(time: 1)
            .done {
                strongSelf.sessions.append(session)
            }
            return session
        }
    }
    
    // MARK: System messages conversation
    
    public func getSystemMessageSession(id: String, fetchHistory: Bool = true) -> RongCloudSystemMessageSession {
        if let session = self.sessions.first(where: { (s) -> Bool in
            return s is RongCloudSystemMessageSession && s.id == id
        }) as? RongCloudSystemMessageSession {
            return session
        }
        
        let session = RongCloudSystemMessageSession(service: self, id: id, fetchHistory: fetchHistory)
        sessions.append(session)
        return session
    }
    
    public func getExistingSystemMessageSession() -> RongCloudSystemMessageSession? {
        return self.sessions.first(where: { (s) -> Bool in
            return s is RongCloudSystemMessageSession
        }) as? RongCloudSystemMessageSession
    }
    
    // MARK: Receiving messages
    
    public func onReceived(_ message: RCMessage!, left nLeft: Int32, object: Any!) {
        var msg: RongCloudMessage? = nil
        if message.content is RCTextMessage {
            msg = RongCloudTextMessage(message: message)
        } else if message.content is RCImageMessage {
            msg = RongCloudImageMessage(message: message)
        } else if message.content is RCVoiceMessage {
            msg = RongCloudAudioMessage(message: message)
        } else if message.content is RCEventMessage {
            msg = RongCloudEventMessage(message: message)
        }
        
        if let nmsg = msg {
            if let session = self.sessions.first(where: { $0.id == message.targetId }) {
                // 已存在会话
                session.receiveMessage(message: nmsg)
            } else {
                // 不存在的会话
                if message.conversationType == RCConversationType.ConversationType_GROUP {
                    _ = self.getGroupSession(withGroupId: message.targetId)
                    .done {session in
                        session.receiveMessage(message: nmsg)
                    }
                } else if message.conversationType == RCConversationType.ConversationType_PRIVATE {
                    _ = self.getPrivateSession(withUserId: message.targetId)
                    .done {session in
                        session.receiveMessage(message: nmsg)
                    }
                } else if message.conversationType == RCConversationType.ConversationType_SYSTEM {
                    let session = self.getSystemMessageSession(id: message.targetId)
                    session.receiveMessage(message: nmsg)
                }
            }
        }
    }
    
    
    // 注册设备推送码
    public func setDeviceToken(deviceToken : String) {
        guard let deviceToken = deviceToken.on_blankToNil() else {
            return
        }
        client.setDeviceToken(deviceToken)
    }
    
    
    
    public func onConnectionStatusChanged(_ status: RCConnectionStatus) {
        if status == .ConnectionStatus_Unconnected || status == .ConnectionStatus_DISCONN_EXCEPTION || status == .ConnectionStatus_NETWORK_UNAVAILABLE || status == .ConnectionStatus_SERVER_INVALID || status == .ConnectionStatus_VALIDATE_INVALID || status == .ConnectionStatus_AIRPLANE_MODE || status == .ConnectionStatus_UNKNOWN {
            // disconnected
            self.status = .disconnected
            
            // notify
            // self.notifyService?.newIMCount = 0
            // self.notifyService?.performIMCountRefresh()
            
        } else if status == .ConnectionStatus_KICKED_OFFLINE_BY_OTHER_CLIENT {
            // kicked
            self.status = .kicked
            
        } else if status == .ConnectionStatus_Connected || status == .ConnectionStatus_WIFI || status == .ConnectionStatus_Cellular_2G || status == .ConnectionStatus_Cellular_3G_4G {
            // connected
            self.status = .connected
        }
    }
    
    
    
    
    
    public func isUserBlocked(userId: String) -> Promise<Bool> {
        return Promise<Bool>{ seal in
            client.getBlacklistStatus(userId, success: { (result) in
                seal.fulfill(result == 0)
            }, error: { (error) in
                seal.reject(ONError.error(code: .RongCloudCode, userInfo: ["error" : error]))
            })
        }
    }
    
    /// 屏蔽用户
    public func blockUser(userId : String) -> Promise<Void> {
        return Promise<Void>{ seal in
            client.add(toBlacklist: userId, success: { () -> Void in
                seal.fulfill(())
            }) { (error) -> Void in
                seal.reject(ONError.error(code: .RongCloudCode, userInfo: ["error" : error]))
            }
        }
    }
    
    /// 去掉屏蔽用户
    public func unblockUser(userId : String) {
        client.remove(fromBlacklist: userId, success: nil, error: nil)
    }
    
    func removeMessageById(messageId: Int) {
        client.deleteMessages([messageId])
    }
}
