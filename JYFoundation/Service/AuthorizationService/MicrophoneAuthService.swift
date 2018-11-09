//
//  MicrophoneAuthService.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/29.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit
import AVFoundation
import PromiseKit


public class MicrophoneAuthService: AuthServiceBase {
    
    public static var shared: MicrophoneAuthService = MicrophoneAuthService()
    
    public override func authState() -> Promise<AuthState> {
        return Promise<AuthState> { seal in
            let state = AVCaptureDevice.authorizationStatus(for: .audio)
            switch (state) {
            case .notDetermined:
                seal.fulfill(AuthState.notDetermined)
            case .restricted:
                fallthrough
            case .denied:
                seal.fulfill(AuthState.denined)
            case .authorized:
                seal.fulfill(AuthState.allowed)
            }
        }
    }
    
    public override func requestAuth() -> Promise<AuthState> {
        return Promise<AuthState> { seal in
            AVCaptureDevice.requestAccess(for: .audio) { (flag) in
                seal.fulfill(flag ? AuthState.allowed : AuthState.denined)
            }
        }
    }
    
    public override func denyWarning(controller: UIViewController) {
        let alert = UIAlertController(title: "麦克风权限被关闭", message: "请允许使用您的麦克风以用于语音聊天。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .cancel, handler: nil))
        controller.present(alert, animated: true, completion: nil)
    }
}
