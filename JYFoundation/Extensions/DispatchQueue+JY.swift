//
//  DispatchQueue+JY.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/12.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import PromiseKit

extension DispatchQueue {

    @discardableResult
    public func jy_delay(time: TimeInterval) -> Promise<Void> {
        return Promise<Void> { seal in
            let time = DispatchTime.now() + .milliseconds(Int(time * 1000))
            self.asyncAfter(deadline: time, execute: {
                seal.fulfill(())
            })
        }
    }
}
