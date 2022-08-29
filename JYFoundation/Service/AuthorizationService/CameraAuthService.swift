//
//  CameraAuthService.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/30.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit
import AVFoundation
import PromiseKit


public class CameraAuthService: AuthServiceBase {
    
    public static var shared: CameraAuthService = CameraAuthService()
    
    public override func authState() -> Promise<AuthState> {
        return Promise<AuthState> { seal in
            let state = AVCaptureDevice.authorizationStatus(for: .video)
            switch (state) {
            case .notDetermined:
                seal.fulfill(AuthState.notDetermined)
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
            AVCaptureDevice.requestAccess(for: .video) { (flag) in
                seal.fulfill(flag ? AuthState.allowed : AuthState.denined)
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
