//
//  JYIMChatRoom.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/8/9.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation

open class JYIMChatRoom: Equatable{
    public static func == (lhs: JYIMChatRoom, rhs: JYIMChatRoom) -> Bool {
        return lhs.chatRoomId == rhs.chatRoomId
    }
    
    public var chatRoomId: String
    public var name: String
    public var cover: String?
    
    public init(chatRoomId: String, name: String, cover: String?) {
        self.chatRoomId = chatRoomId
        self.name = name
        self.cover = cover
    }
}
