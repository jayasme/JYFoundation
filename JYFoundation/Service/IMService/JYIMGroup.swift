//
//  JYIMGroup.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/6/24.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation

open class JYIMGroup: Equatable{
    public static func == (lhs: JYIMGroup, rhs: JYIMGroup) -> Bool {
        return lhs.groupId == rhs.groupId
    }
    
    public var groupId: String
    public var name: String
    public var cover: String?
    
    public init(groupId: String, name: String, cover: String?) {
        self.groupId = groupId
        self.name = name
        self.cover = cover
    }
}
