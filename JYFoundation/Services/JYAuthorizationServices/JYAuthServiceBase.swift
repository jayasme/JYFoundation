//
//  IAuthService.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/29.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import PromiseKit


public enum JYAuthState: Int {
    case notDetermined = 0
    case allowed = 1
    case allowedInUse = 2
    case denined = 3
    case limited = 4
}

open class JYAuthServiceBase {
    
    open var authState: JYAuthState {
        fatalError("Not implemented.")
    }
    
    open func requestAuth() async -> JYAuthState {
        fatalError("Not implemented.")
    }
    
    open func gotoSettings() async {
        fatalError("Not implemented.")
    }
    
    public func request() async -> JYAuthState {
        let auth = self.authState
        if (auth == .notDetermined) {
            return await self.requestAuth()
        } else {
            return auth
        }
    }
}
