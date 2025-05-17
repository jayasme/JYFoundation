//
//  JYMicrophoneAuthService.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/29.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit
import AVFoundation

public class JYMicrophoneAuthService: JYAuthServiceBase {
    
    public static var shared: JYCameraAuthService = JYCameraAuthService()
    
    public override var authState: JYAuthState {
        let state = AVCaptureDevice.authorizationStatus(for: .audio)
        return self.convertAuthState(state)
    }
    
    public override func requestAuth() async -> JYAuthState {
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { state in
                let res = self.convertAuthState(state)
                continuation.resume(
                    returning: res
                )
            }
        }
    }
    
    func convertAuthState(_ state: Any) -> JYAuthState {
        guard let state = state as? Bool else {
            fatalError()
        }
        
        return state ? .allowed : .denined
    }
}
