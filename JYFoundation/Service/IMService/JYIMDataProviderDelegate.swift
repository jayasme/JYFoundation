//
//  JYIMDataProviderDelegate.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/6/24.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import PromiseKit

public protocol JYIMDataProviderDelegate: class {
    func user(with userId: String) -> Promise<JYIMUser>
    func users(with userIds: [String]) -> Promise<[JYIMUser]>
    func group(with groupId: String) -> Promise<JYIMGroup>
    func groups() -> Promise<[JYIMGroup]>
}
