//
//  JYHttpClient.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/4.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import HandyJSON

public class JYHttpClient: NSObject {
    
    public static var shared = JYHttpClient(timeoutInterval: 10, encoder: JYPostJsonBodyEncoder.shared)

    public init(timeoutInterval: TimeInterval, encoder: ParameterEncoding = URLEncoding.default) {
        self.timeoutInterval = timeoutInterval
        self.encoder = encoder
    }
    
    private(set) var timeoutInterval: TimeInterval {
        didSet {
            guard let session = _session else {
                return
            }
            
            session.sessionConfiguration.timeoutIntervalForRequest = timeoutInterval
            session.sessionConfiguration.timeoutIntervalForResource = timeoutInterval
        }
    }
    
    private var _session: Session!
    
    private var encoder: ParameterEncoding
    
    private func session() -> Alamofire.Session {
        if _session == nil {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = timeoutInterval
            configuration.timeoutIntervalForResource = timeoutInterval
            _session = Session(configuration: configuration)
        }
        return _session
    }
    
    @discardableResult
    public func fetchObject<T: JYHttpModel>(_ urlString: String, method: HTTPMethod, header: [String: String]? = nil, parameter: JYHttpParameter? = nil, type: T.Type) -> Promise<T> {
        print("Start fetching object from: " + urlString)
        
        return self.fetchData(urlString, method: method, header: header, parameter: parameter)
        .map { data -> T in
            guard let json = String(data: data, encoding: String.Encoding.utf8), let result = JSONDeserializer<T>.deserializeFrom(json: json) else {
                print("Fetching data failed: ")
                print("[Fallback data] ")
                print(String(data: data, encoding: String.Encoding.utf8) ?? "")
                
                throw JYError("Data deserialization error.", userInfo: ["url": urlString])
            }
            
            return result
        }
    }
    
    @discardableResult
    public func fetchData(_ urlString: String, method: HTTPMethod, header: [String: String]? = nil, parameter: JYHttpParameter? = nil) -> Promise<Data> {
        print("Start fetching data from: " + urlString)
        
        return Promise<Data> { seal in
            guard let url = try? urlString.asURL() else {
                seal.reject(JYError("Invalid url", userInfo: ["url": urlString]))
                return
            }
            
            let paramters: [String: Any]? = parameter?.toJSON()
            let headers = HTTPHeaders(header ?? [:])
            
            self.session().request(url,
                              method: method,
                              parameters: paramters,
                              encoding: (method == .post ? encoder: URLEncoding.default),
                              headers: headers
            ).response(completionHandler: { (response) in
                if response.error != nil {
                    seal.reject(response.error!)
                    return
                }
                
                guard let statusCode = response.response?.statusCode else {
                    seal.reject(JYError("No data fetched.", userInfo: ["url" : urlString]))
                    return
                }
                
                guard statusCode >= 200 && statusCode < 300 else {
                    let error = JYError("Received incorrect status code", userInfo: [
                        "url" : urlString,
                        "statusCode": String(statusCode)
                    ])
                    print(String(format: "Fetching %@ failed:\n %@", urlString, error.message))
                    if let data = response.data, let string = String(data: data, encoding: String.Encoding.utf8) {
                        print("Error response: " + string)
                    }
                    seal.reject(error)
                    return
                }
                
                guard let data = response.data else {
                    seal.reject(JYError("No data fetched.", userInfo: ["url" : urlString]))
                    return
                }
                
                seal.fulfill(data)
            })
        }
    }
    
    @discardableResult
    public func fetchImageData(_ urlString: String, method: HTTPMethod, header: [String: String]? = nil, parameter: JYHttpParameter? = nil) -> Promise<UIImage> {
        return self.fetchData(urlString, method: method, header: header, parameter: parameter)
        .map { data in
            guard let image = UIImage.init(data: data) else {
                throw JYError("Image deserialization error.", userInfo: ["url" : urlString])
            }
            
            return image
        }
    }
    
    @discardableResult
    public func fetchImage(_ urlString: String, method: HTTPMethod, header: [String: String]? = nil, parameter: JYHttpParameter? = nil) -> Promise<UIImage> {
        return self.fetchData(urlString, method: method, header: header, parameter: parameter)
            .map { data in
                guard let image = UIImage.init(data: data) else {
                    throw JYError("Image deserialization error.", userInfo: ["url" : urlString])
                }
                
                return image
        }
    }
    
    @discardableResult
    public func uploadImageData(_ urlString: String, method: HTTPMethod, header: [String: String]? = nil, parameter: JYHttpParameter? = nil, images: [UIImage]? = nil) -> Promise<Data> {
        return Promise<Data> { seal in
            guard let url = try? urlString.asURL() else {
                seal.reject(JYError("Invalid url" + urlString))
                return
            }
            
            let paramters: [String: Any]? = parameter?.toJSON()
            let headers = HTTPHeaders(header ?? [:])
            
            self.session().upload(
                multipartFormData: { (multipartFormData) in
                // 添加上传参数
                if let params = paramters {
                    for (key, value) in params {
                        // 参数的上传
                        if let valueData = (value as AnyObject).data(using: String.Encoding.utf8.rawValue) {
                            multipartFormData.append(valueData, withName: key)
                        }
                    }
                }
                
                // 添加图片
                guard let images = images, !images.isEmpty else {
                    return
                }
                
                for (index, value) in images.enumerated() {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyyMMddHHmmss"
                    let str = formatter.string(from: Date())
                    let fileName = str+"\(index)"+".jpg"
                    if let imageData = value.jpegData(compressionQuality: 0.5) {
                        multipartFormData.append(imageData, withName: "fileupload", fileName: fileName, mimeType: "image/jpeg")
                    }
                    // 以文件流格式上传
                    // 批量上传与单张上传，后台语言为java或.net等
//                    multipartFormData.append(imageData!, withName: "fileupload", fileName: fileName, mimeType: "image/jpeg")
                    
                    // 批量上传，后台语言为PHP。 注意：此处服务器需要知道，前台传入的是一个图片数组
//                    multipartFormData.append(imageData!, withName: "fileupload[\(index)]", fileName: fileName, mimeType: "image/jpeg")
                }
            },
                to: url,
                method: method,
                headers: headers)
            .responseJSON(completionHandler: { response in

                if let error = response.error {
                    seal.reject(error)
                    return
                }
                        
                guard let statusCode = response.response?.statusCode else {
                    seal.reject(JYError("No data uploadImage.", userInfo: ["url" : urlString]))
                    return
                }
                
                guard statusCode >= 200 && statusCode < 300 else {
                    let error = JYError("Error code " + String(statusCode))
                    print(String(format: "uploadImage %@ failed:\n %@", urlString, error.message))
                    if let data = response.data, let string = String(data: data, encoding: String.Encoding.utf8) {
                        print("Error response: " + string)
                    }
                    seal.reject(error)
                    return
                }
                
                guard let data = response.data else {
                    seal.reject(JYError("No data uploadImage.", userInfo: ["url" : urlString]))
                    return
                }
                
                seal.fulfill(data)
            })
        }
    }
    
    @discardableResult
    public func uploadImage<T: JYHttpModel>(_ urlString: String, method: HTTPMethod, header: [String: String]? = nil, parameter: JYHttpParameter? = nil, images: [UIImage]? = nil, type: T.Type) -> Promise<T> {
        print("Start uploadImage from: " + urlString)
        return self.uploadImageData(urlString, method: method, header: header, parameter: parameter, images: images).map { data -> T in
            guard let json = String(data: data, encoding: String.Encoding.utf8), let result = JSONDeserializer<T>.deserializeFrom(json: json) else {
                print("upload data failed: ")
                print("[Fallback data] ")
                print(String(data: data, encoding: String.Encoding.utf8) ?? "")
                
                throw JYError("Data deserialization error.", userInfo: ["url" : urlString])
            }
           
            return result
        }
    }
}
