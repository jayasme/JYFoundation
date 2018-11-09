//
//  JYIMPushNotificationDataProviderDelegate.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/8/23.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation

public protocol JYIMPushNotificationProviderDataSource: class {
    func pushContentText(session: JYIMSessionBase, user: JYIMUser, text: String) -> String?
    func pushDataText(session: JYIMSessionBase,user: JYIMUser, text: String) -> [String: Any]?
    func pushContentImage(session: JYIMSessionBase,user: JYIMUser, image: UIImage) -> String?
    func pushDataImage(session: JYIMSessionBase,user: JYIMUser, image: UIImage) -> [String: Any]?
    func pushContentAudio(session: JYIMSessionBase,user: JYIMUser, audio: Data, duration: TimeInterval) -> String?
    func pushDataAudio(session: JYIMSessionBase,user: JYIMUser, audio: Data, duration: TimeInterval) -> [String: Any]?
    func pushContentEvent(session: JYIMSessionBase,user: JYIMUser, content: String, payload: [String: Any]?) -> String?
    func pushDataEvent(session: JYIMSessionBase,user: JYIMUser, content: String, payload: [String: Any]?) -> [String: Any]?
}
