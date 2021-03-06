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
            guard let manager = _manager else {
                return
            }
            
            manager.session.configuration.timeoutIntervalForRequest = timeoutInterval
            manager.session.configuration.timeoutIntervalForResource = timeoutInterval
        }
    }
    
    private var _manager: SessionManager!
    
    private var encoder: ParameterEncoding
    
    private func manager() -> Alamofire.SessionManager {
        if _manager == nil {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = timeoutInterval
            configuration.timeoutIntervalForResource = timeoutInterval
            _manager = SessionManager(configuration: configuration)
        }
        return _manager
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
                
                throw ONError.error(code: .HTTPClientCode, description: "Data deserialization error.", url: urlString)
            }
            
            return result
        }
    }
    
    @discardableResult
    public func fetchData(_ urlString: String, method: HTTPMethod, header: [String: String]? = nil, parameter: JYHttpParameter? = nil) -> Promise<Data> {
        print("Start fetching data from: " + urlString)
        
        return Promise<Data> { seal in
            guard let url = try? urlString.asURL() else {
                seal.reject(ONError.error(code: .HTTPClientCode, description: "Invalid url" + urlString))
                return
            }
            
            let paramters: [String: Any]? = parameter?.toJSON()
            let headers = header ?? [:]
            
            manager().request(url,
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
                    seal.reject(ONError.error(code: .HTTPClientCode, description: "No data fetched.", url: urlString))
                    return
                }
                
                guard statusCode >= 200 && statusCode < 300 else {
                    let error = ONError.error(code: .HTTPClientCode, description: "Error code " + String(statusCode))
                    print(String(format: "Fetching %@ failed:\n %@", urlString, error))
                    if let data = response.data, let string = String(data: data, encoding: String.Encoding.utf8) {
                        print("Error response: " + string)
                    }
                    seal.reject(error)
                    return
                }
                
                guard let data = response.data else {
                    seal.reject(ONError.error(code: .HTTPClientCode, description: "No data fetched.", url: urlString))
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
                throw ONError.error(code: .HTTPClientCode, description: "Image deserialization error.", url: urlString)
            }
            
            return image
        }
    }
    
    @discardableResult
    public func fetchImage(_ urlString: String, method: HTTPMethod, header: [String: String]? = nil, parameter: JYHttpParameter? = nil) -> Promise<UIImage> {
        return self.fetchData(urlString, method: method, header: header, parameter: parameter)
            .map { data in
                guard let image = UIImage.init(data: data) else {
                    throw ONError.error(code: .HTTPClientCode, description: "Image deserialization error.", url: urlString)
                }
                
                return image
        }
    }
    
    @discardableResult
    public func uploadImageData(_ urlString: String, method: HTTPMethod, header: [String: String]? = nil, parameter: JYHttpParameter? = nil, images: [UIImage]? = nil) -> Promise<Data> {
        return Promise<Data> { seal in
            guard let url = try? urlString.asURL() else {
                seal.reject(ONError.error(code: .HTTPClientCode, description: "Invalid url" + urlString))
                return
            }
            
            let paramters: [String: Any]? = parameter?.toJSON()
            let headers = header ?? [:]
            
            manager().upload(multipartFormData: { (multipartFormData) in
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
                    if let imageData = UIImageJPEGRepresentation(value, 0.5) {
                        multipartFormData.append(imageData, withName: "fileupload", fileName: fileName, mimeType: "image/jpeg")
                    }
                    // 以文件流格式上传
                    // 批量上传与单张上传，后台语言为java或.net等
//                    multipartFormData.append(imageData!, withName: "fileupload", fileName: fileName, mimeType: "image/jpeg")
                    
                    // 批量上传，后台语言为PHP。 注意：此处服务器需要知道，前台传入的是一个图片数组
//                    multipartFormData.append(imageData!, withName: "fileupload[\(index)]", fileName: fileName, mimeType: "image/jpeg")
                }
            }, to: url, method: method, headers: headers, encodingCompletion: { (encodingResult) in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        print("response = \(response)")
                        if response.error != nil {
                            seal.reject(response.error!)
                            return
                        }
                        
                        guard let statusCode = response.response?.statusCode else {
                            seal.reject(ONError.error(code: .HTTPClientCode, description: "No data uploadImage.", url: urlString))
                            return
                        }
                        
                        guard statusCode >= 200 && statusCode < 300 else {
                            let error = ONError.error(code: .HTTPClientCode, description: "Error code " + String(statusCode))
                            print(String(format: "uploadImage %@ failed:\n %@", urlString, error))
                            if let data = response.data, let string = String(data: data, encoding: String.Encoding.utf8) {
                                print("Error response: " + string)
                            }
                            seal.reject(error)
                            return
                        }
                        
                        guard let data = response.data else {
                            seal.reject(ONError.error(code: .HTTPClientCode, description: "No data uploadImage.", url: urlString))
                            return
                        }
                        
                        seal.fulfill(data)
                    }
                case .failure(let encodingError):
                    seal.reject(encodingError)
                }
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
                
                throw ONError.error(code: .HTTPClientCode, description: "Data deserialization error.", url: urlString)
            }
           
            return result
        }
    }
}
