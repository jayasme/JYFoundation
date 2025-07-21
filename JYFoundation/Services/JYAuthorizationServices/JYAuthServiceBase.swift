//
//  IAuthService.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/29.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import PromiseKit


public enum JYAuthState: String {
    case notDetermined = "notDetermined"
    case allowed = "allowed"
    case allowedInUse = "allowedInUse"
    case denined = "denined"
    case limited = "limited"
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
