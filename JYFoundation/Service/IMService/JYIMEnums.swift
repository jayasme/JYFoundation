//
//  ONIMEnums.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/20.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation


public enum JYIMServiceStatus: Int {
    case unknown = 0
    case disconnected = 1
    case connecting = 2
    case receiving = 3
    case connected = 4
    case kicked = 5
}

public enum JYIMMessageType: Int {
    case unknown = 0
    case text = 1
    case image = 2
    case audio = 3
    case event = 4
}

public enum JYIMMessageDirection: Int {
    case send = 1
    case receive = 2
}

public enum JYIMMessageStatus: Int {
    case unknown = 0
    case sending = 1
    case sent = 2
    case failed = 3
    case received = 4
    case read = 5
}

public enum JYIMCoversationType {
    case `private`
    case chatRoom
    case discussion
}
