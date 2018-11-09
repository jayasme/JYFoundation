//
//  IAuthService.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/29.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import PromiseKit


public enum AuthState: Int {
    case notDetermined = 0
    case allowed = 1
    case denined = 2
}

open class AuthServiceBase {
    
    open func authState() -> Promise<AuthState> {
        fatalError("Not implemented.")
    }
    
    open func requestAuth() -> Promise<AuthState> {
        fatalError("Not implemented.")
    }
    
    open func denyWarning(controller: UIViewController) {
        fatalError("Not implemented.")
    }
    
    public func request() -> Promise<AuthState> {
        return authState()
        .then { state -> Promise<AuthState> in
            if (state == .notDetermined) {
                return self.requestAuth()
            } else {
                return Promise<AuthState>.value(state)
            }
        }
    }
}
