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
    
    var keyWindow: UIWindow? {
        if #available(iOS 15.0, *) {
            return self.connectedScenes.filter { $0.activationState == .foregroundActive }
                // Keep only active scenes, onscreen and visible to the user
                .filter { $0.activationState == .foregroundActive }
                // Keep only the first `UIWindowScene`
                .first(where: { $0 is UIWindowScene })
                // Get its associated windows
                .flatMap({ $0 as? UIWindowScene })?.windows
                // Finally, keep only the key window
                .first(where: \.isKeyWindow)
        } else {
            return self.windows.filter {$0.isKeyWindow}.first
        }
    }
}
