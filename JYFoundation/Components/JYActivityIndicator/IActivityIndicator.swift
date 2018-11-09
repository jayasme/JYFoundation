//
//  IActivityIndicator.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/26.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation


protocol IActivityIndicator: class {

    var isAnimating : Bool {get set}
    
    func startAnimation()
    func stopAnimation()
}
