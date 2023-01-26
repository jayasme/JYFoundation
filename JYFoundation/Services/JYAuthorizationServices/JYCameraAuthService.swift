//
//  JYCameraAuthService.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/30.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit
import AVFoundation
import PromiseKit


public class JYCameraAuthService: JYAuthServiceBase {
    
    public static var shared: JYCameraAuthService = JYCameraAuthService()
    
    public override func authState() -> Promise<JYAuthState> {
        return Promise<JYAuthState> { seal in
            let state = AVCaptureDevice.authorizationStatus(for: .video)
            switch (state) {
            case .notDetermined:
                seal.fulfill(JYAuthState.notDetermined)
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
            AVCaptureDevice.requestAccess(for: .video) { (flag) in
                seal.fulfill(flag ? JYAuthState.allowed : JYAuthState.denined)
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
