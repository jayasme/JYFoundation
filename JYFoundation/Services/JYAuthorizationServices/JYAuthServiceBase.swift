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
    case denined = 2
}

open class JYAuthServiceBase {
    
    public private(set) var denyTitle: String?
    public private(set) var denyMessage: String?
    
    open func authState() -> Promise<JYAuthState> {
        fatalError("Not implemented.")
    }
    
    open func requestAuth() -> Promise<JYAuthState> {
        fatalError("Not implemented.")
    }
    
    open func denyWarning(controller: UIViewController) {
        fatalError("Not implemented.")
    }
    
    public func request() -> Promise<JYAuthState> {
        return authState()
        .then { state -> Promise<JYAuthState> in
            if (state == .notDetermined) {
                return self.requestAuth()
            } else {
                return Promise<JYAuthState>.value(state)
            }
        }
    }
}
