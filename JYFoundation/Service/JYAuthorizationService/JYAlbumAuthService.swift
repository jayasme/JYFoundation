//
//  JYAlbumAuthService.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/30.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import PromiseKit
import Photos

public class JYAlbumAuthService: JYAuthServiceBase {
    
    public static var shared: JYAlbumAuthService = JYAlbumAuthService()
    
    public override func authState() -> Promise<JYAuthState> {
        return Promise<JYAuthState> { seal in
            let state = PHPhotoLibrary.authorizationStatus()
            switch (state) {
            case .notDetermined:
                seal.fulfill(JYAuthState.notDetermined)
            case .limited:
                fallthrough
            case .restricted:
                fallthrough
            case .denied:
                seal.fulfill(JYAuthState.denined)
            case .authorized:
                seal.fulfill(JYAuthState.allowed)
            @unknown default:
                fatalError()
            }
        }
    }
    
    public override func requestAuth() -> Promise<JYAuthState> {
        return Promise<JYAuthState> { seal in
            PHPhotoLibrary.requestAuthorization({ (state) in
                seal.fulfill(state == .authorized ? JYAuthState.allowed : JYAuthState.denined)
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
