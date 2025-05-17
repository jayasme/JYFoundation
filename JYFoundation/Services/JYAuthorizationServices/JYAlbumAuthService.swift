//
//  JYAlbumAuthService.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/30.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import Photos

public class JYAlbumAuthService: JYAuthServiceBase {
    
    public static var shared: JYAlbumAuthService = JYAlbumAuthService()
    
    public override var authState: JYAuthState {
        let state = PHPhotoLibrary.authorizationStatus()
        return self.convertAuthState(state)
    }
    
    public override func requestAuth() async -> JYAuthState {
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { state in
                let res = self.convertAuthState(state)
                continuation.resume(
                    returning: res
                )
            }
        }
    }
    
    func convertAuthState(_ state: Any) -> JYAuthState {
        guard let state = state as? PHAuthorizationStatus else {
            fatalError()
        }
        switch (state) {
        case .notDetermined:
            return .notDetermined
        case .limited:
            return .limited
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
}
