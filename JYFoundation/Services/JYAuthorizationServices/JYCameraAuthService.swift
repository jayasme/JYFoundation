//
//  JYCameraAuthService.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/30.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit
import AVFoundation

extension Notification.Name {
    public static let JYCameraAuthStateUpdate = Notification.Name("JYCameraAuthStateUpdate")
}

public class JYCameraAuthService: JYAuthServiceBase {
    
    public static var shared: JYCameraAuthService = JYCameraAuthService()
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onAppActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onAppInactive),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name:UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name:UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    public override var authState: JYAuthState {
        let state = AVCaptureDevice.authorizationStatus(for: .video)
        return self.convertAuthState(state)
    }
    
    public override func requestAuth() async -> JYAuthState {
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { state in
                NotificationCenter.default.post(name: .JYCameraAuthStateUpdate, object: nil, userInfo: ["authState": state])
                continuation.resume(
                    returning: state ? .allowed : .denined
                )
            }
        }
    }
    
    func convertAuthState(_ state: Any) -> JYAuthState {
        guard let state = state as? AVAuthorizationStatus else {
            fatalError()
        }
        
        switch (state) {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            fallthrough
        case .denied:
            return .denined
        case .authorized:
            return .allowed
        @unknown default:
            fatalError()
        }
    }
    
    private var lastState: JYAuthState?
    @objc func onAppActive() {
        guard self.authState != lastState else {
            return
        }
        
        NotificationCenter.default.post(name: .JYCameraAuthStateUpdate, object: nil, userInfo: ["authState": self.authState])
    }
    
    @objc func onAppInactive() {
        self.lastState = self.authState
    }
}
