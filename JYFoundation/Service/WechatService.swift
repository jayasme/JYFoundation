//
//  WechatService.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/14.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import PromiseKit

public class WechatAccessTokenModel: JYHttpModel {
    var errcode: Int?
    var access_token: String!
    var refresh_token: String!
    var openid: String!
}

public class WechatServiceUserInfo: JYHttpModel {
    var errcode: Int?
    var nickname: String?
    var sex: Int?
    var province: String?
    var city: String?
    var headimgurl: String?
}

public class WechatService : NSObject, WXApiDelegate {
    
    private var _appId : String!
    
    private var callback : ((BaseResp) -> Void)? = nil
    
    private(set) var accessToken : String? = nil
    private(set) var refreshToken : String? = nil
    private(set) var openId : String? = nil
    
    public static func isSupport() -> Bool {
        return (WXApi.isWXAppInstalled() && WXApi.isWXAppSupport())
    }
    
    public init(appId : String) {
        self._appId = appId
        WXApi.registerApp(self._appId)
    }
    
    /// 请求微信认证code
    public func requestAuthorizationCode(viewController: UIViewController) -> Promise<String> {
        return Promise<String> {[weak self] seal in
            guard let strongSelf = self else { return }
            // 打开微信
            let request = SendAuthReq()
            request.scope = "snsapi_userinfo"
            strongSelf.callback = {(resp) -> () in
                guard let response = resp as? SendAuthResp else { return }
                
                guard response.errCode == 0, let responseCode = response.code else {
                    seal.reject(ONError.error(code: .WechatSDKClientCode, description: response.errStr ?? ""))
                    return
                }
                
                seal.fulfill(responseCode)
            }
            WXApi.sendAuthReq(request, viewController: viewController, delegate: nil)
        }
    }
    
    /// 请求微信登录
    public func requestAuthorization(viewController: UIViewController) -> Promise<WechatAccessTokenModel> {
        return Promise<WechatAccessTokenModel> {[weak self] seal in
            guard let strongSelf = self else { return }
            // 打开微信
            let request = SendAuthReq()
            request.scope = "snsapi_userinfo"
            strongSelf.callback = {(resp) -> () in
                guard let response = resp as? SendAuthResp else { return }
                
                guard response.errCode == 0 else {
                    seal.reject(ONError.error(code: .WechatSDKClientCode, description: response.errStr ?? ""))
                    return
                }
                
                strongSelf.requestAccessToken(code: response.code)
                .done { model in
                    seal.fulfill(model)
                }.catch{ error in
                    seal.reject(error)
                }
            }
            WXApi.sendAuthReq(request, viewController: viewController, delegate: nil)
        }
    }
    
    
    /// 分享URL图片到微信
    public func shareToFriends(title : String, description : String, url : String, thumbnailURL : String) -> Promise<SendMessageToWXResp> {
        return JYHttpClient.shared.fetchImage(thumbnailURL, method: .get).then { image in
            self.privateShare(title: title, url: url, description: nil, thumbnail: image, scene: 0)
        }
    }
    
    /// 分享到URL图片朋友圈
    public func shareToMoments(title : String, url : String, thumbnailURL : String) -> Promise<SendMessageToWXResp> {
        // download the image first
        return JYHttpClient.shared.fetchImage(thumbnailURL, method: .get).then { image in
            self.privateShare(title: title, url: url, description: nil, thumbnail: image, scene: 1)
        }
    }
    
    public func shareToFriends(title : String, description : String, url : String, thumbnail : UIImage) -> Promise<SendMessageToWXResp> {
        return privateShare(title: title, url: url, description: description, thumbnail: thumbnail, scene: 0)
    }
    
    public func shareToMoments(title : String, url : String, thumbnail : UIImage) -> Promise<SendMessageToWXResp> {
        return privateShare(title: title, url: url, description: nil, thumbnail: thumbnail, scene: 1)
    }
    
    fileprivate func privateShare(title : String, url : String, description : String?, thumbnail : UIImage, scene: Int32) -> Promise<SendMessageToWXResp> {
        return Promise<SendMessageToWXResp> {[weak self] seal in
            guard let strongSelf = self else { return }
            
            // check the thumbnail
            let obj = WXWebpageObject()
            obj.webpageUrl = url
            let message = WXMediaMessage()
            message.title = title
            if let description = description {
                message.description = description
            }
            message.mediaObject = obj
            message.setThumbImage(thumbnail)

            let request = SendMessageToWXReq()
            request.scene = scene
            request.bText = false
            request.message = message
            
            strongSelf.callback = {(resp) -> () in
                guard let response = resp as? SendMessageToWXResp else { return }
                guard response.errCode == 0 else {
                    seal.reject(ONError.error(code: .WechatSDKClientCode, description: ""))
                    return
                }
                seal.fulfill(response)
            }
            WXApi.send(request)
        }
    }
    
    public func requestAccessToken(code : String) -> Promise<WechatAccessTokenModel> {
        let url = String(format: "http://on2017.com/iservice/weixin/access_token.do?code=%@", code)
        return JYHttpClient.shared.fetchObject(url, method: .get, type: WechatAccessTokenModel.self)
    }
    
    public func requestUserInfo() -> Promise<WechatServiceUserInfo> {
        guard let accessToken = accessToken, let openId = openId else {
            return Promise(error: ONError.error(code: .WechatSDKClientCode, description: "Access token or openId is nil"))
        }
        // https://api.weixin.qq.com/sns/oauth2/access_token?appid=APPID&secret=SECRET&code=CODE&grant_type=authorization_code
        let url = String(format: "https://api.weibo.com/2/users/show.json?access_token=%@&uid=%@", accessToken, openId)
        return JYHttpClient.shared.fetchObject(url, method: .get, type: WechatServiceUserInfo.self)
    }
    
    /// handle the url
    public func handleURL(url : URL) -> Bool {
        return WXApi.handleOpen(url, delegate: self)
    }
    
    public func onResp(_ resp: BaseResp!) {
        callback?(resp)
    }
}
