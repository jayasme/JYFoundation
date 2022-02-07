//
//  UIApplication+JY.swift
//  JYFoundation
//
//  Created by 荣超 on 2022/2/6.
//  Copyright © 2022 jayasme. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    
    public var currentKeyWindow: UIWindow? {
        if #available(iOS 15.0, *) {
            return self.connectedScenes
                .filter { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
                .first(where: { $0 is UIWindowScene })
                .flatMap({ $0 as? UIWindowScene })?.windows
                .first{ $0.isKeyWindow }
        } else {
            return self.windows.filter {$0.isKeyWindow}.first
        }
    }
}
