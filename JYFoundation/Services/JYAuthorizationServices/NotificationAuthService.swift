//
//  JYNotificationAuthService.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/8/11.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import PromiseKit
import UserNotifications

public class JYNotificationAuthService: JYAuthServiceBase {
    
    public static var shared: JYNotificationAuthService = JYNotificationAuthService()
    
    public override func authState() -> Promise<JYAuthState> {
        return Promise<JYAuthState> { seal in
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                switch(settings.authorizationStatus) {
                case .authorized:
                    fallthrough
                case .provisional:
                    fallthrough
                case .ephemeral:
                    seal.fulfill(JYAuthState.allowed)
                    break
                case .denied:
                    seal.fulfill(JYAuthState.denined)
                    break
                case .notDetermined:
                    seal.fulfill(JYAuthState.notDetermined)
                    break
                @unknown default:
                    fatalError()
                }
            }
        }
    }
    
    public override func requestAuth() -> Promise<JYAuthState> {
        let notificationOptions: UNAuthorizationOptions = [.alert , .badge, .sound]
        return Promise<JYAuthState> { seal in
            UNUserNotificationCenter.current().requestAuthorization(options: notificationOptions) { (granted, error) in
                seal.fulfill(granted ? JYAuthState.allowed : JYAuthState.denined)
            }
        }
    }
    
    public override func denyWarning(controller: UIViewController) {
        guard let denyTitle = self.denyTitle, let denyMessage = self.denyMessage else {
            return
        }
        let alert = UIAlertController(title: denyTitle, message: denyMessage, preferredStyle: .alert)
        controller.present(alert, animated: true, completion: nil)
    }
}
