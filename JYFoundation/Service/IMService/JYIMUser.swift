//
//  ONIMUser.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/6/10.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation

open class JYIMUser: Equatable {
    public static func == (lhs: JYIMUser, rhs: JYIMUser) -> Bool {
        return lhs.userId == rhs.userId
    }
    
    public var userId: String
    public var name: String
    public var avatar: String?
    
    public init(userId: String, name: String, avatar: String?) {
        self.userId = userId
        self.name = name
        self.avatar = avatar
    }
}
