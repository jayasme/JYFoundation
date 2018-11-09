//
//  NotificationAuthService.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/8/11.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import PromiseKit
import UserNotifications

public class NotificationAuthService: AuthServiceBase {
    
    public static var shared: NotificationAuthService = NotificationAuthService()
    
    public override func authState() -> Promise<AuthState> {
        return Promise<AuthState> { seal in
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                switch(settings.authorizationStatus) {
                case .authorized:
                    seal.fulfill(AuthState.allowed)
                    break
                case .denied:
                    seal.fulfill(AuthState.denined)
                    break
                case .notDetermined:
                    seal.fulfill(AuthState.notDetermined)
                    break
                }
            }
        }
    }
    
    public override func requestAuth() -> Promise<AuthState> {
        let notificationOptions: UNAuthorizationOptions = [.alert , .badge, .sound]
        return Promise<AuthState> { seal in
            UNUserNotificationCenter.current().requestAuthorization(options: notificationOptions) { (granted, error) in
                seal.fulfill(granted ? AuthState.allowed : AuthState.denined)
            }
        }
    }
    
    public override func denyWarning(controller: UIViewController) {
        let alert = UIAlertController(title: "推送通知被关闭", message: "开启通知能让你获得最新的消息和通知。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .cancel, handler: nil))
        controller.present(alert, animated: true, completion: nil)
    }
}
