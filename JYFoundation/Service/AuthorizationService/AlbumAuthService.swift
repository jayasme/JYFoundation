//
//  AlbumAuthService.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/30.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import PromiseKit
import Photos

public class AlbumAuthService: AuthServiceBase {
    
    public static var shared: AlbumAuthService = AlbumAuthService()
    
    public override func authState() -> Promise<AuthState> {
        return Promise<AuthState> { seal in
            let state = PHPhotoLibrary.authorizationStatus()
            switch (state) {
            case .notDetermined:
                seal.fulfill(AuthState.notDetermined)
            case .limited:
                fallthrough
            case .restricted:
                fallthrough
            case .denied:
                seal.fulfill(AuthState.denined)
            case .authorized:
                seal.fulfill(AuthState.allowed)
            @unknown default:
                fatalError()
            }
        }
    }
    
    public override func requestAuth() -> Promise<AuthState> {
        return Promise<AuthState> { seal in
            PHPhotoLibrary.requestAuthorization({ (state) in
                seal.fulfill(state == .authorized ? AuthState.allowed : AuthState.denined)
            })
        }
    }
    
    public override func denyWarning(controller: UIViewController) {
        let alert = UIAlertController(title: "相册权限被关闭", message: "请允许使用您的相册以用于发送图片。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .cancel, handler: nil))
        controller.present(alert, animated: true, completion: nil)
    }
}
