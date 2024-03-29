//
//  ICellViewModel.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/4/30.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation

public protocol ICellViewModel: AnyObject {
    var model: Any? { get set }
    func shouldHighlight() -> Bool
    func didSelect()
    func updateModel(_ model: Any?)
}

public enum JYViewStatus: Int {
    case fixed = 0
    case initialLoad = 1
    case loading = 2
    case loaded = 3
    case failure = 4
    case exhausted = 5
}

public enum JYViewDataSourceType: Int {
    case unknwon = 0
    case `static` = 1
    case dynamical = 2
}
