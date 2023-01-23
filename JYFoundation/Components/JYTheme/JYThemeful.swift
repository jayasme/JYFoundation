//
//  JYThemeful.swift
//  JYFoundation
//
//  Created by 荣超 on 2023/1/23.
//  Copyright © 2023 jayasme. All rights reserved.
//

import Foundation

public protocol JYThemeful: AnyObject {
    var themes: [JYTheme] { get set }
    var styleSheet: JYStyleSheet? { get set }
}
