//
//  WeiboService.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/14.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import PromiseKit

public class WeiboServiceUserInfo: JYHttpModel {
    var error_code: NSNumber!
    var screen_name: String?
    var gender: String?
    var location: String?
    var avatar_hd: String?
}

public class WeiboService : NSObject, WeiboSDKDelegate {
    
    private var _appId : String!
    
    private var callback : ((WBBaseResponse) -> ())? = nil
    
    private(set) open var accessToken : String!
    private(set) open var userId : String!

    public init(appId : String) {
        self._appId = appId
        WeiboSDK.registerApp(self._appId)
    }
    
    public static func isSupport() -> Bool {
        return (WeiboSDK.isWeiboAppInstalled() && WeiboSDK.isCanSSOInWeiboApp())
    }
    
    /// 请求微博登录
    public func requestAuthorization() -> Promise<WBAuthorizeResponse> {
        return Promise<WBAuthorizeResponse> { seal in
            // 打开微博
            let request = WBAuthorizeRequest()
            request.scope = "all"
            request.redirectURI = "http://on.com"
            
            self.callback = {[weak self] (resp) -> () in
                guard let strongSelf = self else { return }
                if resp is WBAuthorizeResponse {
                    let response = resp as! WBAuthorizeResponse
                    
                    if response.statusCode == .success {
                        // 成功
                        strongSelf.accessToken = response.accessToken
                        strongSelf.userId = response.userID
                        seal.fulfill(response)
                    } else {
                        // 失败
                        seal.reject(ONError.error(code: .WeiboSDKClientCode, description: "Login error."))
                    }
                }
            }
            WeiboSDK.send(request)
        }
    }
    
    public func requestUserInfo() -> Promise<WeiboServiceUserInfo> {
        let url = String(format: "https://api.weibo.com/2/users/show.json?access_token=%@&uid=%@", accessToken, userId)
        return JYHttpClient.shared.fetchObject(url, method: .get, type: WeiboServiceUserInfo.self)
    }
    
    public func sendToWeibo(text : String?, image : String?) -> Promise<WBSendMessageToWeiboResponse> {

        let message = WBMessageObject()
        message.text = text ?? ""
        
        // 下载图片
        if let imageUrl = image?.on_emptyToNil() {
            return JYHttpClient.shared.fetchData(imageUrl, method: .get).then { data -> Promise<WBSendMessageToWeiboResponse> in
                guard data.count < 10485760 else {
                    throw ONError.error(code: .WeiboSDKClientCode, description: "Image too large.")
                }
                
                let imageObject = WBImageObject()
                imageObject.imageData = data
                message.imageObject = imageObject
                
                return self.sendToWeibo(with: message)
            }
        } else {
            return sendToWeibo(with: message)
        }
    }
    
    private func sendToWeibo(with messageObject: WBMessageObject) -> Promise<WBSendMessageToWeiboResponse> {
        
        return Promise<WBSendMessageToWeiboResponse> { seal in

            let request = WBSendMessageToWeiboRequest()
            request.message = messageObject
            
            self.callback = {(resp) -> () in
                
                if resp is WBSendMessageToWeiboResponse {
                    let response = resp as! WBSendMessageToWeiboResponse
                    
                    if response.statusCode == .success {
                        seal.fulfill(response)
                    } else {
                        seal.reject(ONError.error(code: .WeiboSDKClientCode, description: "Sent failed."))
                    }
                }
            }
            WeiboSDK.send(request)
        }
    }
    
    /// 用于捕获URL
    public func handleURL(url : URL) -> Bool {
        return WeiboSDK.handleOpen(url, delegate: self)
    }
    
    public func didReceiveWeiboRequest(_ request: WBBaseRequest!) { }
    
    public func didReceiveWeiboResponse(_ response: WBBaseResponse!) {
        // 接受回调
        self.callback?(response)
    }
}
