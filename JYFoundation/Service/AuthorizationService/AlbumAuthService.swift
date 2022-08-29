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
        guard let denyTitle = self.denyTitle, let denyMessage = self.denyMessage else {
            return
        }
        let alert = UIAlertController(title: denyTitle, message: denyMessage, preferredStyle: .alert)
        controller.present(alert, animated: true, completion: nil)
    }
}
